// Stub for platforms where dart:html is not available.
class HtmlWindow {
  void open(String url, String name) {
    throw UnsupportedError('HTML window is not supported on this platform.');
  }
}

final window = HtmlWindow();
