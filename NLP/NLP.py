import nltk
import re
import time

SEPARATORS = ['.', ',', ':', ';', '?', '!']
NOUNS_TAGS = ['NN', 'NNP', 'NNS', 'NNPS']

def getWords(text):
    sentances = nltk.sent_tokenize(text)
    phrases = []

    for sentance in sentances:
        phrases.append(nltk.word_tokenize(sentance))

    return phrases

def getNoums(text):
    sentances = nltk.sent_tokenize(text)
    nouns = []

    for sentance in sentances:
        words = nltk.word_tokenize(sentance)
        sentanceNouns = []
        indexes = []

        i = 0
        for word, tag in nltk.pos_tag(words):
            if(tag in NOUNS_TAGS):
                sentanceNouns.append(word)
                indexes.append(i)

            i += 1

        i = 0
        last = len(sentanceNouns) - 1
        while i < last:
            if indexes[i] + 1 == indexes[i + 1]:
                sentanceNouns[i] += " " + sentanceNouns[i + 1]
                indexes.pop(i + 1)
                sentanceNouns.pop(i + 1)

                last -= 1

            i += 1

        nouns += sentanceNouns

    return nouns

def getStems(phrases):
    stemmer = nltk.stem.porter.PorterStemmer()
    stems = []
    for sentance in phrases:
        for word in sentance:
            if word not in SEPARATORS:
                stems.append(stemmer.stem(word))

    return stems


def main():
    textFile = open('randomLetter.txt', 'r')
    text = textFile.read()
    phrases = getWords(text)
    print phrases
    print getStems(phrases)
    print getNoums(text)
    return 0

if __name__ == '__main__':
    main()