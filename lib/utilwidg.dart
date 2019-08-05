//this is for functions which would otherwise go into util.dart, but do not because they deal with widgets and UI stuff (usually are passed a widget or state as a parameter)
//i created this file when i added file attach functionality to the reply dialog
import 'package:file_picker/file_picker.dart';

//presents file picker interface.
Future getFile(state) async{ //currently supports one file; will provide multiple files in future if necessary
  var f = await FilePicker.getFile(type: FileType.ANY);
  state.setState((){
    state.file = f; //this is bad because getFile() the passed in state HAS to have 'file' var, and this getFile() has to know that
  });
}

//actually realized i over-engineered this (in the case of file picker), so i will not use it, but will leave the file here for historical purposes and incase it becomes useful later
