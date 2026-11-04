/// Retorna false quando a cópia com formatação não é possível na plataforma.
bool copyRichTextToClipboard({required String html, required String plainText}) => false;

/// Retorna false quando o download não é possível na plataforma.
bool downloadWordDocument({required String fileName, required String content}) => false;
