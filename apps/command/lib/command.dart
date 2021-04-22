import 'dart:io';

import 'package:args/args.dart';

class CommandError extends Error {
  final String message;
  CommandError(this.message);
}

abstract class Command {
  final ArgParser parser;
  Command(this.parser);

  get usage {
    return "Usage: " +
        Platform.executable +
        " [OPTION] [PATH]\n" +
        parser.usage;
  }

  void run(List<String> arguments);

  void main(List<String> arguments) async {
    try {
      await run(arguments);
    } on CommandError catch (error) {
      print("${error.message}");
      print(usage);
      exitCode = -1;
    } catch (error) {
      print(usage);
      exitCode = -1;
    }
  }
}
