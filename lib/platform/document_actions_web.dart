import 'dart:convert';
import 'dart:html' as web;

bool copyRichTextToClipboard({required String html, required String plainText}) {
  final textArea = web.TextAreaElement()
    ..value = plainText
    ..style.position = 'fixed'
    ..style.left = '-9999px'
    ..style.top = '0';

  web.document.body?.append(textArea);
  textArea.focus();
  textArea.select();

  void onCopy(web.Event e) {
    final clipboardEvent = e as web.ClipboardEvent;
    clipboardEvent.clipboardData?.setData('text/html', html);
    clipboardEvent.clipboardData?.setData('text/plain', plainText);
    e.preventDefault();
  }

  web.document.addEventListener('copy', onCopy);
  final result = web.document.execCommand('copy');
  web.document.removeEventListener('copy', onCopy);
  textArea.remove();
  return result;
}

bool downloadWordDocument({required String fileName, required String content}) {
  try {
    final encoded = base64Encode(utf8.encode(content));
    web.AnchorElement(href: 'data:application/msword;base64,$encoded')
      ..setAttribute('download', fileName)
      ..click();
    return true;
  } catch (_) {
    return false;
  }
}
