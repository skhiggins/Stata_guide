#!/usr/bin/env python3
"""
Scrape PDFs from CBO (Congressional Budget Office) publication pages.

This script extracts and downloads all PDF files linked from a CBO publication page.
It supports multiple methods to handle sites with bot protection:
1. Direct HTTP requests (default)
2. Curl subprocess (--use-curl)
3. Selenium browser automation (--use-selenium)

IMPORTANT: The CBO website uses DataDome bot protection which requires JavaScript
execution. The --use-selenium option is recommended for reliable access.

Usage:
    python scrape_cbo_pdfs.py <publication_url> [options]

Examples:
    # Basic usage (may be blocked by bot protection)
    python scrape_cbo_pdfs.py https://www.cbo.gov/publication/61837

    # Using Selenium (recommended for CBO)
    python scrape_cbo_pdfs.py https://www.cbo.gov/publication/61837 --use-selenium

    # With custom output directory
    python scrape_cbo_pdfs.py https://www.cbo.gov/publication/61837 -o ./cbo_pdfs --use-selenium

    # List PDFs without downloading
    python scrape_cbo_pdfs.py https://www.cbo.gov/publication/61837 --list-only --use-selenium

Requirements:
    Base: pip install requests beautifulsoup4
    Selenium mode: pip install selenium webdriver-manager

    For Selenium, you also need Chrome/Chromium browser installed:
    - macOS: brew install google-chrome
    - Ubuntu/Debian: apt install chromium-browser
    - Or download from: https://www.google.com/chrome/

Note on CBO PDF URL patterns:
    CBO typically hosts PDFs at: https://www.cbo.gov/system/files/YYYY-MM/filename.pdf
    Example: https://www.cbo.gov/system/files/2025-01/60870-Outlook-2025.pdf
"""

import argparse
import os
import re
import subprocess
import sys
import time
import random
from pathlib import Path
from urllib.parse import urljoin, urlparse

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Error: Required packages not installed.")
    print("Install them with: pip install requests beautifulsoup4")
    sys.exit(1)


# Browser-like headers
DEFAULT_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
}


def get_publication_id(url: str) -> str:
    """Extract publication ID from CBO URL."""
    match = re.search(r'/publication/(\d+)', url)
    return match.group(1) if match else "unknown"


def create_session() -> requests.Session:
    """Create a requests session with browser-like settings."""
    session = requests.Session()
    session.headers.update(DEFAULT_HEADERS)
    return session


def fetch_page_with_curl(url: str) -> str:
    """Fetch page content using curl subprocess."""
    try:
        result = subprocess.run(
            [
                'curl', '-s', '-L',
                '-A', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                '-H', 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                '-H', 'Accept-Language: en-US,en;q=0.9',
                '--compressed',
                url
            ],
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode != 0:
            raise Exception(f"curl failed with code {result.returncode}: {result.stderr}")
        return result.stdout
    except FileNotFoundError:
        raise Exception("curl not found. Please install curl.")


def fetch_page_with_selenium(url: str) -> str:
    """Fetch page content using Selenium browser automation."""
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
    except ImportError:
        print("Selenium not installed. Install with:")
        print("  pip install selenium webdriver-manager")
        raise

    options = Options()
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36')

    # Try to find Chrome binary in common locations
    chrome_paths = [
        '/root/.cache/ms-playwright/chromium-1194/chrome-linux/chrome',
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser',
        '/snap/bin/chromium',
    ]

    chrome_binary = None
    for path in chrome_paths:
        if os.path.exists(path):
            chrome_binary = path
            break

    if chrome_binary:
        options.binary_location = chrome_binary

    # Try to use webdriver-manager or system chromedriver
    service = None
    try:
        from webdriver_manager.chrome import ChromeDriverManager
        service = Service(ChromeDriverManager().install())
    except Exception:
        # Try common chromedriver locations
        chromedriver_paths = [
            '/usr/bin/chromedriver',
            '/usr/local/bin/chromedriver',
        ]
        for path in chromedriver_paths:
            if os.path.exists(path):
                service = Service(path)
                break

    if service:
        driver = webdriver.Chrome(service=service, options=options)
    else:
        driver = webdriver.Chrome(options=options)

    try:
        driver.get(url)
        # Wait for page to load and bypass any CAPTCHA challenges
        time.sleep(5)  # Give time for any JS challenges to complete
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )
        # Additional wait for dynamic content
        time.sleep(2)
        return driver.page_source
    finally:
        driver.quit()


def fetch_page_with_requests(url: str, session: requests.Session = None, max_retries: int = 4) -> str:
    """Fetch page content with retry logic and exponential backoff."""
    if session is None:
        session = create_session()

    headers = {'Referer': 'https://www.cbo.gov/'}

    for attempt in range(max_retries):
        try:
            if attempt > 0:
                time.sleep(random.uniform(1, 3))

            response = session.get(url, headers=headers, timeout=30, allow_redirects=True)
            response.raise_for_status()
            return response.text

        except requests.RequestException as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** (attempt + 1) + random.uniform(0, 1)
                print(f"Retry {attempt + 1}/{max_retries} after {wait_time:.1f}s: {e}")
                time.sleep(wait_time)
            else:
                raise

    return ""


def fetch_page(url: str, method: str = 'requests', session: requests.Session = None) -> str:
    """Fetch page content using specified method."""
    if method == 'curl':
        print("Using curl...")
        return fetch_page_with_curl(url)
    elif method == 'selenium':
        print("Using Selenium browser automation...")
        return fetch_page_with_selenium(url)
    else:
        return fetch_page_with_requests(url, session)


def extract_pdf_links(html: str, base_url: str) -> list[dict]:
    """Extract all PDF links from the page."""
    soup = BeautifulSoup(html, 'html.parser')
    pdf_links = []
    seen_urls = set()

    # Find all links that point to PDFs
    for link in soup.find_all('a', href=True):
        href = link['href']

        # Check if it's a PDF link
        if '.pdf' in href.lower():
            # Make absolute URL
            full_url = urljoin(base_url, href)

            # Skip duplicates
            if full_url in seen_urls:
                continue
            seen_urls.add(full_url)

            # Get link text for description
            link_text = link.get_text(strip=True) or "Unknown"

            # Extract filename from URL
            parsed = urlparse(full_url)
            filename = os.path.basename(parsed.path)

            pdf_links.append({
                'url': full_url,
                'filename': filename,
                'description': link_text
            })

    return pdf_links


def download_pdf_with_curl(url: str, output_path: Path) -> bool:
    """Download a PDF file using curl."""
    try:
        result = subprocess.run(
            [
                'curl', '-s', '-L', '-o', str(output_path),
                '-A', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                '-H', 'Referer: https://www.cbo.gov/',
                '--compressed',
                url
            ],
            capture_output=True,
            timeout=120
        )
        return result.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0
    except Exception as e:
        print(f"  curl download failed: {e}")
        return False


def download_pdf(url: str, output_path: Path, session: requests.Session = None, max_retries: int = 4) -> bool:
    """Download a PDF file with retry logic."""
    if session is None:
        session = create_session()

    headers = {'Referer': 'https://www.cbo.gov/'}

    for attempt in range(max_retries):
        try:
            if attempt > 0:
                time.sleep(random.uniform(1, 2))

            response = session.get(url, headers=headers, timeout=60, stream=True, allow_redirects=True)
            response.raise_for_status()

            # Verify it's actually a PDF
            content_type = response.headers.get('content-type', '')
            if 'pdf' not in content_type.lower() and not url.endswith('.pdf'):
                print(f"  Warning: Content-Type is {content_type}, may not be a PDF")

            with open(output_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            return True

        except requests.RequestException as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** (attempt + 1) + random.uniform(0, 1)
                print(f"  Retry {attempt + 1}/{max_retries} after {wait_time:.1f}s: {e}")
                time.sleep(wait_time)
            else:
                print(f"  Failed to download: {e}")
                return False

    return False


def scrape_cbo_pdfs(
    publication_url: str,
    output_dir: str = None,
    method: str = 'requests',
    session: requests.Session = None
) -> list[str]:
    """
    Scrape all PDFs from a CBO publication page.

    Args:
        publication_url: URL of the CBO publication page
        output_dir: Directory to save PDFs (default: ./cbo_pdfs_<publication_id>)
        method: Method to use ('requests', 'curl', 'selenium')
        session: Optional requests session to reuse

    Returns:
        List of paths to downloaded PDF files
    """
    if session is None:
        session = create_session()

    # Validate URL
    if 'cbo.gov' not in publication_url:
        print(f"Warning: URL does not appear to be from cbo.gov: {publication_url}")

    pub_id = get_publication_id(publication_url)
    print(f"Scraping CBO publication {pub_id}: {publication_url}")

    # Set up output directory
    if output_dir is None:
        output_dir = f"cbo_pdfs_{pub_id}"
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {output_path.absolute()}")

    # Fetch the page
    print("\nFetching publication page...")
    try:
        html = fetch_page(publication_url, method=method, session=session)
    except Exception as e:
        print(f"Error fetching page: {e}")
        if method == 'requests':
            print("\nTip: The site may be blocking requests. Try with --use-curl or --use-selenium")
        return []

    # Extract PDF links
    print("Extracting PDF links...")
    pdf_links = extract_pdf_links(html, publication_url)

    if not pdf_links:
        print("No PDF links found on this page.")
        return []

    print(f"Found {len(pdf_links)} PDF(s):\n")
    for i, pdf in enumerate(pdf_links, 1):
        desc = pdf['description'][:60] + "..." if len(pdf['description']) > 60 else pdf['description']
        print(f"  {i}. {pdf['filename']}")
        print(f"     Description: {desc}")
        print(f"     URL: {pdf['url']}")
        print()

    # Download PDFs
    downloaded = []
    print("Downloading PDFs...\n")

    for i, pdf in enumerate(pdf_links, 1):
        filename = pdf['filename']
        # Sanitize filename
        filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
        file_path = output_path / filename

        print(f"[{i}/{len(pdf_links)}] Downloading: {filename}")

        if file_path.exists():
            print(f"  Skipped (already exists)")
            downloaded.append(str(file_path))
            continue

        # Add delay between downloads
        if i > 1:
            time.sleep(random.uniform(1, 3))

        # Try downloading - use curl for PDFs if main method is curl
        success = False
        if method == 'curl':
            success = download_pdf_with_curl(pdf['url'], file_path)
        else:
            success = download_pdf(pdf['url'], file_path, session)
            # Fall back to curl if requests fails
            if not success:
                print("  Trying curl as fallback...")
                success = download_pdf_with_curl(pdf['url'], file_path)

        if success:
            size_mb = file_path.stat().st_size / (1024 * 1024)
            print(f"  Downloaded ({size_mb:.2f} MB)")
            downloaded.append(str(file_path))
        else:
            print(f"  Failed")

    # Summary
    print(f"\n{'='*50}")
    print(f"Summary: Downloaded {len(downloaded)}/{len(pdf_links)} PDFs")
    print(f"Location: {output_path.absolute()}")

    return downloaded


def main():
    parser = argparse.ArgumentParser(
        description="Scrape PDFs from CBO publication pages",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s https://www.cbo.gov/publication/61837
  %(prog)s https://www.cbo.gov/publication/61837 --output-dir ./my_pdfs
  %(prog)s https://www.cbo.gov/publication/61837 --use-curl
  %(prog)s https://www.cbo.gov/publication/61837 --use-selenium
        """
    )
    parser.add_argument(
        'url',
        help='CBO publication URL (e.g., https://www.cbo.gov/publication/61837)'
    )
    parser.add_argument(
        '-o', '--output-dir',
        help='Directory to save downloaded PDFs (default: cbo_pdfs_<publication_id>)'
    )
    parser.add_argument(
        '--list-only',
        action='store_true',
        help='Only list PDFs without downloading'
    )
    parser.add_argument(
        '--use-curl',
        action='store_true',
        help='Use curl subprocess (may bypass some restrictions)'
    )
    parser.add_argument(
        '--use-selenium',
        action='store_true',
        help='Use Selenium browser automation (required for sites with bot protection)'
    )

    args = parser.parse_args()

    # Determine method
    if args.use_selenium:
        method = 'selenium'
    elif args.use_curl:
        method = 'curl'
    else:
        method = 'requests'

    session = create_session()

    if args.list_only:
        # Just list the PDFs
        print(f"Fetching: {args.url}")
        try:
            html = fetch_page(args.url, method=method, session=session)
            pdf_links = extract_pdf_links(html, args.url)
            print(f"\nFound {len(pdf_links)} PDF(s):\n")
            for i, pdf in enumerate(pdf_links, 1):
                print(f"{i}. {pdf['filename']}")
                print(f"   URL: {pdf['url']}")
                print(f"   Description: {pdf['description']}")
                print()
        except Exception as e:
            print(f"Error: {e}")
            if method == 'requests':
                print("\nTip: Try with --use-curl or --use-selenium flag")
            sys.exit(1)
    else:
        # Download PDFs
        downloaded = scrape_cbo_pdfs(
            args.url,
            args.output_dir,
            method=method,
            session=session
        )
        if not downloaded:
            sys.exit(1)


if __name__ == '__main__':
    main()
