using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;

namespace Olympus {
    // https://github.com/maddie480/RandomStuffWebsite/blob/main/src/main/java/ovh/maddie480/randomstuff/frontend/CelesteModSearchService.java
    // but it's entirely client-side because some poor souls can't access maddie480.ovh (yay!)

    class GameBananaAPIEmulator {
        private static List<Dictionary<string, object>> everything;
        public static List<Dictionary<string, object>> Get() {
            if (everything == null) {
                using (HttpClient client = new HttpClientWithCompressionSupport())
                using (Stream inputStream = client.GetAsync("https://everestapi.github.io/updatermirror/mod_search_database.yaml").Result.Content.ReadAsStream())
                using (TextReader reader = new StreamReader(inputStream)) {
                    everything = YamlHelper.Deserializer.Deserialize<List<Dictionary<string, object>>>(reader);
                }
            }

            return everything;
        }
    }

    public class CmdEmulatedModList : Cmd<string, int, string, int?, int?, string> {
        public override string Run(string sort, int page, string type, int? category, int? subcategory) {
            // is there a type and/or a category filter?
            List<Predicate<Dictionary<string, object>>> typeFilters = new List<Predicate<Dictionary<string, object>>>();
            if (type != null) {
                typeFilters.Add(info => type.Equals(info["GameBananaType"]));
            }
            if (category != null) {
                typeFilters.Add(info => category == int.Parse((string) info["CategoryId"]));
            }
            if (subcategory != null) {
                typeFilters.Add(info => info.ContainsKey("SubcategoryId") && subcategory == int.Parse((string) info["SubcategoryId"]));
            }
            // typeFilter is a && of all typeFilters
            Predicate<Dictionary<string, object>> typeFilter = info => typeFilters.All(filter => filter(info));

            // determine the field on which we want to sort. Sort by descending id to tell equal values apart.
            IComparer<Dictionary<string, object>> sortComparator;
            switch (sort) {
                case "views":
                    sortComparator = new Sorter("Views");
                    break;
                case "likes":
                    sortComparator = new Sorter("Likes");
                    break;
                case "downloads":
                    sortComparator = new Sorter("Downloads");
                    break;
                default:
                    sortComparator = new Sorter("CreatedDate");
                    break;
            }

            // then sort on it.
            List<Dictionary<string, object>> response = GameBananaAPIEmulator.Get()
                .Where(d => typeFilter.Invoke(d))
                .OrderBy(d => d, sortComparator)
                .Skip((page - 1) * 20)
                .Take(20)
                .ToList();

            return JsonConvert.SerializeObject(response);
        }

        private class Sorter(string field) : IComparer<Dictionary<string, object>> {
            public int Compare(Dictionary<string, object> x, Dictionary<string, object> y) {
                int diff = int.Parse((string) y[field]) - int.Parse((string) x[field]);
                if (diff != 0) return diff;
                return int.Parse((string) x["GameBananaId"]) - int.Parse((string) y["GameBananaId"]);
            }
        }
    }

    public partial class CmdEmulatedModSearch : Cmd<string, string> {
        public override string Run(string query) {
            string[] tokenizedRequest = tokenize(query);

            List<Dictionary<string, object>> response = GameBananaAPIEmulator.Get()
                .Select(m => new Tuple<Dictionary<string, object>, double>(m, scoreMod(tokenizedRequest, tokenize((string) m["Name"]))))
                .Where(m => m.Item2 > 0.2 * tokenizedRequest.Length)
                .OrderBy(m => m, new Sorter())
                .Select(m => m.Item1)
                .Take(20)
                .ToList();

            return JsonConvert.SerializeObject(response);
        }

        private class Sorter : IComparer<Tuple<Dictionary<string, object>, double>> {
            public int Compare(Tuple<Dictionary<string, object>, double> x, Tuple<Dictionary<string, object>, double> y) {
                double diff = y.Item2 - x.Item2;
                if (diff != 0) return Math.Sign(diff);
                return int.Parse((string) y.Item1["Downloads"]) - int.Parse((string) x.Item1["Downloads"]);
            }
        }

        private static double scoreMod(string[] query, string[] modName) {
            double score = 0;

            foreach (string tokenSearch in query) {
                if (tokenSearch.EndsWith('*')) {
                    // "starts with" search: add 1 if there's a word starting with the prefix
                    string tokenSearchStart = tokenSearch.Substring(0, tokenSearch.Length - 1);
                    foreach (string tokenModName in modName) {
                        if (tokenModName.StartsWith(tokenSearchStart)) {
                            score++;
                            break;
                        }
                    }
                } else {
                    // "equals" search: take the score of the word that is closest to the token
                    double tokenScore = 0;
                    foreach (string tokenModName in modName) {
                        tokenScore = Math.Max(tokenScore, Math.Pow(0.5, levenshteinDistance(tokenSearch, tokenModName)));
                    }
                    score += tokenScore;
                }
            }

            return score;
        }

        private static string[] tokenize(string s) {
            s = removeDiacritics(s.ToLowerInvariant()) // "Pokémon" => "pokemon"
                .Replace("'", ""); // "Maddie's Helping Hand" => "maddies helping hand"
            s = notDigitOrLetter().Replace(s, " "); // "The D-Sides Pack" => "the d sides pack"
            while (s.Contains("  ")) s = s.Replace("  ", " ");
            return s.Split(" ");
        }

        // Source - https://stackoverflow.com/a/249126
        // Posted by Blair Conrad, modified by community. See post 'Timeline' for change history
        // Retrieved 2025-11-09, License - CC BY-SA 4.0
        private static string removeDiacritics(string text) {
            var normalizedString = text.Normalize(NormalizationForm.FormD);
            var stringBuilder = new StringBuilder(capacity: normalizedString.Length);

            for (int i = 0; i < normalizedString.Length; i++) {
                char c = normalizedString[i];
                var unicodeCategory = CharUnicodeInfo.GetUnicodeCategory(c);
                if (unicodeCategory != UnicodeCategory.NonSpacingMark) {
                    stringBuilder.Append(c);
                }
            }

            return stringBuilder
                .ToString()
                .Normalize(NormalizationForm.FormC);
        }

        // Source - https://www.dotnetperls.com/levenshtein
        private static int levenshteinDistance(string s, string t) {
            int n = s.Length;
            int m = t.Length;
            int[,] d = new int[n + 1, m + 1];

            // Verify arguments.
            if (n == 0) {
                return m;
            }
            if (m == 0) {
                return n;
            }

            // Initialize arrays.
            for (int i = 0; i <= n; d[i, 0] = i++) {
            }
            for (int j = 0; j <= m; d[0, j] = j++) {
            }

            // Begin looping.
            for (int i = 1; i <= n; i++) {
                for (int j = 1; j <= m; j++) {
                    // Compute cost.
                    int cost = (t[j - 1] == s[i - 1]) ? 0 : 1;
                    d[i, j] = Math.Min(
                        Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1),
                        d[i - 1, j - 1] + cost);
                }
            }
            // Return cost.
            return d[n, m];
        }

        [GeneratedRegex("[^a-z0-9* ]")]
        private static partial Regex notDigitOrLetter();
    }
}
