## What's this?

A simple command-line application to scrape Noblesse Webtoon series chapters (from unofficial sources). I made it entirely for personal purposes, but hey if it's useful to you as well then that's great.

## How to run?

📌 Using docker:

```sh
docker build -t noblesse_scraper .
docker run --rm -v $(pwd):/app/output noblesse_scraper -o output [OPTIONS]
```

📌 Using the pre-compiled binary from releases:

Just do that lol. It's only available for Linux though.

## Options

```
noblesse_scraper: A simple command-line application to scrape Noblesse Webtoon series chapters.


-o, --output-directory=<path>    Output directory for the downloaded chapters.
                                 (defaults to "Noblesse")
-c, --chapter                    Comma separated list of chapters to download. This is ignored if `--to-chapter` and `--from-chapter` are defined.
-f, --from-chapter               Used in conjunction with `--to-chapter` to download a range of chapters.
-t, --to-chapter                 Used in conjunction with `--from-chapter` to download a range of chapters.
-z, --zip                        Zip the chapters once downloaded.
-h, --help                       Show this message.
```