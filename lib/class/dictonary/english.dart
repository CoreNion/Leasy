import 'dart:math';

/// 英語の辞書(単語リスト)
///
/// 品詞ごとにリストを作成
class EnglishDictonary {
  final List<String> noun;
  final List<String> preposition;
  final List<String> adjective;
  final List<String> verb;
  final List<String> adverb;
  final List<String> prefix;
  final List<String> interjection;
  final List<String> conjunction;
  final List<String> pronoun;

  EnglishDictonary(
      this.noun,
      this.preposition,
      this.adjective,
      this.verb,
      this.adverb,
      this.prefix,
      this.interjection,
      this.conjunction,
      this.pronoun);

  factory EnglishDictonary.fromJson(Map<String, dynamic> json) {
    return EnglishDictonary(
      json['n.'].cast<String>() as List<String>,
      json['prep.'].cast<String>() as List<String>,
      json['a.'].cast<String>() as List<String>,
      json['v.'].cast<String>() as List<String>,
      json['adv.'].cast<String>() as List<String>,
      json['p.'].cast<String>() as List<String>,
      json['interj.'].cast<String>() as List<String>,
      json['conj.'].cast<String>() as List<String>,
      json['pron.'].cast<String>() as List<String>,
    );
  }

  /// 単語が存在するか検索する
  bool search(String word) {
    if (noun.contains(word)) {
      return true;
    } else if (preposition.contains(word)) {
      return true;
    } else if (adjective.contains(word)) {
      return true;
    } else if (verb.contains(word)) {
      return true;
    } else if (adverb.contains(word)) {
      return true;
    } else if (prefix.contains(word)) {
      return true;
    } else if (interjection.contains(word)) {
      return true;
    } else if (conjunction.contains(word)) {
      return true;
    } else if (pronoun.contains(word)) {
      return true;
    } else {
      return false;
    }
  }

  /// 単語の品詞を返す
  String partOfSpeech(String word) {
    if (noun.contains(word)) {
      return 'n.';
    } else if (preposition.contains(word)) {
      return 'prep.';
    } else if (adjective.contains(word)) {
      return 'a.';
    } else if (verb.contains(word)) {
      return 'v.';
    } else if (adverb.contains(word)) {
      return 'adv.';
    } else if (prefix.contains(word)) {
      return 'p.';
    } else if (interjection.contains(word)) {
      return 'interj.';
    } else if (conjunction.contains(word)) {
      return 'conj.';
    } else if (pronoun.contains(word)) {
      return 'pron.';
    } else {
      return '';
    }
  }

  /// 同じ品詞の単語をランダムに返す
  String randomWord(String partOfSpeech) {
    switch (partOfSpeech) {
      case 'n.':
        return noun[Random().nextInt(noun.length)];
      case 'prep.':
        return preposition[Random().nextInt(preposition.length)];
      case 'a.':
        return adjective[Random().nextInt(adjective.length)];
      case 'v.':
        return verb[Random().nextInt(verb.length)];
      case 'adv.':
        return adverb[Random().nextInt(adverb.length)];
      case 'p.':
        return prefix[Random().nextInt(prefix.length)];
      case 'interj.':
        return interjection[Random().nextInt(interjection.length)];
      case 'conj.':
        return conjunction[Random().nextInt(conjunction.length)];
      case 'pron.':
        return pronoun[Random().nextInt(pronoun.length)];
      default:
        return '';
    }
  }
}
