import re
import sys

def extract_changelog(changelog_path="changelog.txt"):
    with open(changelog_path, 'r') as f:
        lines = f.readlines()

    changelog_lines = []
    in_changelog = False
    for line in lines:
        if line.strip() == '#changelog#':
            in_changelog = True
            continue
        if in_changelog and line.strip():
            # Clean the list
            cleaned = re.sub(r'^[∙•\-*\s]+', '', line).strip()
            changelog_lines.append(cleaned)

    # Add <li> and <ul> with correct indentation (pretty ugly)
    xml_lines = [f"          <li>{line}</li>" for line in changelog_lines]
    xml = "\n".join(xml_lines)
    return f"        <ul>\n{xml}\n        </ul>"

def update_metainfo(target, changelog_html):
    with open(target, 'r') as f:
        content = f.read()

    # Replace only the exact placeholder line
    updated = content.replace(
        '<description>BUILD_CHANGELOG</description>',
        f'<description>\n{changelog_html}\n      </description>'
    )

    with open(target, 'w') as f:
        f.write(updated)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        target_path = "lib-linux/io.github.everestapi.Olympus.metainfo.xml"
    else:
        target_path = sys.argv[1]

    changelog_xml = extract_changelog()
    update_metainfo(target_path, changelog_xml)
    print("Metainfo file updated")
