#!/usr/bin/env python3
import sys
import re
import os

def update_readme(version: str, readme_path: str = "README.md"):
    if not os.path.exists(readme_path):
        print(f"Error: {readme_path} not found")
        sys.exit(1)

    with open(readme_path, "r", encoding="utf-8") as f:
        content = f.read()

    table_html = f"""<!-- DOWNLOAD_TABLE_START -->
<table align="center" width="100%">
  <thead>
    <tr>
      <th align="center" width="33%">
        <a href="https://github.com/simple-icons/simple-icons/issues/11236" target="_blank" title="Removal: All Microsoft Icons · Issue #11236 · simple-icons/simple-icons">
          <b>Windows*</b>
        </a>
      </th>
      <th align="center" width="33%">
        <img src="https://cdn.simpleicons.org/linux" height="67" alt="Linux" /><br />
      </th>
      <th align="center" width="33%">
        <img src="https://cdn.simpleicons.org/apple" height="67" alt="macOS" /><br />
      </th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <a href="https://github.com/Ra1nify/Antigravity_Portable/releases/download/{version}/Antigravity-Portable-v{version}-windows-x64.zip"><b>x64 (.zip)</b></a>
        <br /><br />
        <a href="https://github.com/Ra1nify/Antigravity_Portable/releases/download/{version}/Antigravity-Portable-v{version}-windows-arm64.zip"><b>ARM64 (.zip)</b></a>
      </td>
      <td align="center">
        <a href="https://github.com/Ra1nify/Antigravity_Portable/releases/download/{version}/Antigravity-Portable-v{version}-linux-x64.tar.gz"><b>x64 (.tar.gz)</b></a>
        <br /><br />
        <a href="https://github.com/Ra1nify/Antigravity_Portable/releases/download/{version}/Antigravity-Portable-v{version}-linux-arm64.tar.gz"><b>ARM64 (.tar.gz)</b></a>
      </td>
      <td align="center">
        <a href="https://github.com/Ra1nify/Antigravity_Portable/releases/download/{version}/Antigravity-Portable-v{version}-macOS-arm64.zip"><b>Apple Silicon (.zip)</b></a>
        <br /><br />
        <a href="https://github.com/Ra1nify/Antigravity_Portable/releases/download/{version}/Antigravity-Portable-v{version}-macOS-x64.zip"><b>Intel (.zip)</b></a>
      </td>
    </tr>
  </tbody>
</table>

> \\* *Windows icon links to [simple-icons#11236](https://github.com/simple-icons/simple-icons/issues/11236) in honor of Microsoft Legal.*
<!-- DOWNLOAD_TABLE_END -->"""

    # 1. Primary match: by anchor comments
    anchor_pattern = r"<!-- DOWNLOAD_TABLE_START -->.*?<!-- DOWNLOAD_TABLE_END -->"
    table_pattern = r"<table align=[\"']center[\"'] width=[\"']100%[\"']>.*?</table>"
    header_pattern = r"(## Download\s*\n+)"

    if re.search(anchor_pattern, content, flags=re.DOTALL):
        updated = re.sub(anchor_pattern, table_html.strip(), content, flags=re.DOTALL)
        print(f"Matched anchor tags in {readme_path}")
    elif re.search(table_pattern, content, flags=re.DOTALL):
        # Fallback 1: match the <table> directly if anchors were deleted
        updated = re.sub(table_pattern, table_html.strip(), content, flags=re.DOTALL)
        print(f"Fallback: matched table tag directly in {readme_path}")
    elif re.search(header_pattern, content):
        # Fallback 2: insert right under ## Download
        updated = re.sub(header_pattern, r"\1" + table_html.strip() + "\n\n", content)
        print(f"Fallback: inserted table under ## Download in {readme_path}")
    else:
        print(f"Error: Neither anchor tags, table, nor '## Download' found in {readme_path}")
        sys.exit(1)

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(updated)
    print(f"Successfully updated {readme_path} download table to v{version}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python update_readme.py <VERSION> [README_PATH]")
        sys.exit(1)
    path = sys.argv[2] if len(sys.argv) > 2 else "README.md"
    update_readme(sys.argv[1], path)
