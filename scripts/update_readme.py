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
        <img src="https://cdn.simpleicons.org/linux" height="28" alt="Linux" /><br />
        <b>Linux</b>
      </th>
      <th align="center" width="33%">
        <img src="https://cdn.simpleicons.org/apple" height="28" alt="macOS" /><br />
        <b>macOS</b>
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

    pattern = r"<!-- DOWNLOAD_TABLE_START -->.*?<!-- DOWNLOAD_TABLE_END -->"
    if re.search(pattern, content, flags=re.DOTALL):
        updated = re.sub(pattern, table_html.strip(), content, flags=re.DOTALL)
        with open(readme_path, "w", encoding="utf-8") as f:
            f.write(updated)
        print(f"Successfully updated {readme_path} download table to v{version}")
    else:
        print(f"Warning: Anchor tags not found in {readme_path}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python update_readme.py <VERSION> [README_PATH]")
        sys.exit(1)
    path = sys.argv[2] if len(sys.argv) > 2 else "README.md"
    update_readme(sys.argv[1], path)
