String? extractValueOfXmlTag({required String xml, required String xmlTag}) {
  if (!xml.contains(xmlTag)) {
    return null;
  }
  final firstSplit = xml.split('</''$xmlTag>')[0];
  List<String> secondSplit = firstSplit.split('<$xmlTag>');
  if (secondSplit.length == 1) {
    secondSplit = firstSplit.split('<$xmlTag ');
    final value = secondSplit[1].split('>')[1];
    return value;
  }
  final value = secondSplit[1];
  return value;
}

String? extractValueOfXmlTagIgnoringNamespace({
  required String xml,
  required String xmlTag,
}) {
  if (!xml.contains(xmlTag)) {
    return null;
  }
  final String tag = RegExp.escape(xmlTag);
  final RegExp expression = RegExp(
    '<(?:[\\w-]+:)?$tag(?:\\s[^>]*)?>(.*?)</(?:[\\w-]+:)?$tag>',
    dotAll: true,
  );
  final Match? match = expression.firstMatch(xml);
  return match?.group(1)?.trim();
}
