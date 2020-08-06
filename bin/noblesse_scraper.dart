import 'dart:io';
import 'dart:math';
import 'package:meta/meta.dart';
import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:web_scraper/web_scraper.dart';

const downloadUrl = 'https://s3.mangabeast.com/manga/Noblesse/';
const pageCountUrl = 'https://ww2.readnoblesse.com/';

const outputDirectory = 'output-directory';
const chapter = 'chapter';
const fromChapter = 'from-chapter';
const toChapter = 'to-chapter';
const zip = 'zip';
const help = 'help';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      outputDirectory, 
      abbr: 'o', 
      defaultsTo: 'Noblesse', 
      help: 'Output directory for the downloaded chapters.',
      valueHelp: 'path'
    )
    ..addMultiOption(
      chapter, 
      abbr: 'c', 
      defaultsTo: [],
      help: 'Comma separated list of chapters to download. '
        'This is ignored if `--to-chapter` and `--from-chapter` are defined.'
    )
    ..addOption(
      fromChapter, 
      abbr: 'f',
      help: 'Used in conjunction with `--to-chapter` to download a range of chapters.'
    )
    ..addOption(
      toChapter, 
      abbr: 't',
      help: 'Used in conjunction with `--from-chapter` to download a range of chapters.'
    )
    ..addFlag(
      zip, 
      abbr: 'z',
      help: 'Zip the chapters once downloaded.',
      negatable: false
    )
    ..addFlag(
      help, 
      abbr: 'h',
      help: 'Show this message.',
      negatable: false
    );

  final args = parser.parse(arguments);

  if (args[help] || args.arguments.isEmpty) {
    stdout.write(
      '\nnoblesse_scraper: A simple command-line application '
      'to scrape Noblesse Webtoon series chapters.\n\n'
      '${parser.usage}\n'
    );
    exit(0);
  }

  run(args);
}

Future<void> run(ArgResults args) async {
  try {
    Iterable<int> chapters;
    if (args[fromChapter] != null && args[toChapter] != null) {
      final from = int.tryParse(args[fromChapter]);
      final to = int.tryParse(args[toChapter]);
      chapters = Iterable<int>.generate(to - from + 1, (i) => i + from);
    } else {
      final chapterArg = (args[chapter] as Iterable<String>);
      if (chapterArg.isEmpty) return;
      chapters = chapterArg.map(int.parse);
    }

    var output = (args[outputDirectory] as String);
    if (output.endsWith('/')) {
      output = output.substring(0, output.length - 1);
    }

    final shouldZip = args[zip];

    final scrapper = NoblesseScrapper(
      outputDirectory: output,
      shouldZipChapters: shouldZip
    );

    stdout.write('🆗 We are all set. Starting!\n\n');

    for (final chapter in chapters) {
      await scrapper.downloadChapter(chapterNo: chapter);
    }

    stdout.write('\n🏁 Finished! Have a good reading.\n');
    exit(0);
  } on ArgParserException catch (e) {
    stderr.write('❗ ${e.message}');
  }
}

class NoblesseScrapper {
  final String outputDirectory;
  final WebScraper _scrapper;
  final Random _random;
  final bool shouldZipChapters;

  NoblesseScrapper({
    @required this.outputDirectory,
    this.shouldZipChapters = false
  }) : _scrapper = WebScraper('$pageCountUrl'),
      _random = Random();

  Future<void> downloadChapter({int chapterNo = 1}) async {
    stdout.write('🔽 Downloading files for chapter $chapterNo... \r');

    final pageLoaded = await _scrapper.loadWebPage(
      'chapter/noblesse-chapter-${_zeroPad(chapterNo, 3)}/');

    if (!pageLoaded) {
      stderr.write('❗ Error downloading chapter $chapterNo.\n');
      return;
    }

    final pageCount = _scrapper.getElement('img.js-page', []).length;

    final futures = <Future>[];

    final _chapterFileName = 'Ch. $chapterNo';

    for (final index in Iterable<int>.generate(pageCount, (i) => i + 1)) {
      final url =
        '$downloadUrl${_zeroPad(chapterNo, 4)}-${_zeroPad(index, 3)}.png';
      final imgFileName =
        '$outputDirectory/$_chapterFileName/${_chapterFileName}_$index.png';
      futures.add(_downloadImage(url, imgFileName));
    }
    ;

    await Future.wait(futures);
    stdout.write('👌 Done downloading files for chapter $chapterNo.\n');

    if (shouldZipChapters) _zipChapter(chapterNo);
  }

  String _zeroPad(int input, int zeroCount) => 
    '${input.toString().padLeft(zeroCount, '0')}';

  Future<void> _downloadImage(String url, String fileName) async {
    final file = await File(fileName).create(recursive: true);
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      await response.pipe(file.openWrite());
      // Being gentle-ish with the server
      await Future.delayed(Duration(milliseconds: _random.nextInt(5) * 10));
    } catch (_) {
      if (await file.exists()) {
        await file.delete();
      }
      stderr.write('❗ Error downloading file $url.\n');
    }
  }

  void _zipChapter(int chapterNo) {
    stdout.write('📁 Compressing files for chapter $chapterNo... \r');

    final _chapterFileName = 'Ch. $chapterNo';

    final _encoder = ZipFileEncoder();
    _encoder.create('$outputDirectory/$_chapterFileName.zip');
    _encoder.addDirectory(Directory('$outputDirectory/$_chapterFileName'));
    _encoder.close();

    stdout.write('📁 Done compressing files for chapter $chapterNo.\n');
  }
}
