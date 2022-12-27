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