# DifferenceAlgorithmComparison

# Heckel
old, newの2つの配列の差分を考えましょう。

old, new = O, Nとし、以下の様に3つのdata structureを考えます。
1. symbol table
2. OA
3. NA
まずsymbol tableからです。配列O, Nの各要素を symbol table entry のキーとして使用します。
各symbol table entryは2つのカウンターを持っていて、それらをOC, NCとします。このOC, NCはキーとして使用した要素が配列O, Nにいくつ含まれているかを示す値となります。
実は、このカウンターが持つ値としては 0, 1 or manyの3つだけを考えれば十分です。カウンターに加えてもう一つ、symbol table entryはOLNOフィールドを持ちます。OLNOと言われるとなんだこれは？みたいになりますが、これは、symbol tableのキーとなっている要素の `配列O内` でのインデックスを示します。
```swift
<E: Hashable>

var symbolTable: [E: SymbolTableEntry] = [:]

enum Counter {
 case zero, one, many

 mutating func increment() {
  switch self {
   case .zero:
    self = .one
   default:
    self = .many
  }
 }
}

class SymbolTableEntry {
 var oldCounter: Counter
 var newCounter: Counter
 var indicesInOld: [Int]  // OLNO Field
}
```
`1. symbol table` に関しては上記の通り、配列O, Nの各要素がどのくらいの数(Counter)含まれているのか？そして、それは配列Oのどこに(OLNO)含まれているのか？を管理するdata structureです。この管理のためにSymbolTableEntryを持つ辞書型データですが、そのキーとしては配列O, Nの各要素を使用します。

それでは、`2, 3: OA, NA` は何者か。`symbolTable` がSymbolTableEntryを管理していた様に、この2つもEntryを管理する配列です。それでは、何へのEntryか？
`symbol table entry` と `その要素の互いのインデックス` の2つの内どちらかです。後者の `その要素の互いのインデックス` はOAであれば配列Nの、NAであれば配列Oのその要素が現れるインデックスという意味です。共通の要素のインデックスをOとNで交換して管理する様なイメージです。
```swift
enum ElementEntry {
 case symbolTableEntry(SymbolTableEntry)
 case indexForTheOther(Int)
}
```

さて、一度ここまで登場した変数をまとめます。
- symbol table
- Old
  - O: 配列 (oldArray)
  - OA: ElementEntryを管理する配列 (oldElementEntries)
  - OC: Counter (oldCounter)
- New
  - N: 配列 (newArray)
  - NA: ElementEntryを管理する配列 (newElementEntries)
  - NC: Counter (newCounter)

()内はswift化した時の変数名とします。
これ以降、新しい変数は登場せず、これらの変数を組み合わせて行くことで差分を取ることが出来ます。差分を取るまでに6つのStepが必要であり、この手順がHeckelの差分アルゴリズムです。
それでは、1-6 Stepの内 Step-1から見て行きましょう。
```
1. 配列Nの各要素をキーとして、symbol table entryを作成。(ただし、そのキーのentryが存在していない時)
2. その要素のNCをインクリメントする
3. NA[i]にsymbol table entryをセットする。(iはその要素のインデックス)
4. NA[i]をsymbol tableにN[i]をキーとしてセットする。
```
Step-1は比較前の準備と言ったところです。
```swift
newArray.forEach {
 let entry = symbolTable[$0.hashValue] ?? SymbolTableEntry()
 entry.newCounter.increment()
 newElementEntries.append(.symbolTableEntry(entry))
 symbolTable[$0.hashValue] = entry
}
```
Step-2はStep-1と同じ操作をOldに対して行うだけです。ただし、Oldの場合、SymbolTableEntry.indicesInOldの管理も必要ですね。
```swift
oldArray.enumerated().forEach { index, element
 let entry = symbolTable[element.hashValue] ?? TableEntry()
 entry.oldCounter.increment()
 entry.indicesInOld.append(index)
 oldElementEntries.append(.symbolTableEntry(entry))
 symbolTable[element.hashValue] = entry
}
```
すでに、6つの内、2つのStepが完了しました。

これからStep-3, 4, 5に移ります。この3つのStepを大まかに説明すると、Step-1, 2で設定したentryは `.symbolTableEntry`だけでした。これから、それらを可能な限り `indexForTheOther` に変えて行きます。そうなると、最終的には `.symbolTableEntry` は共通で持たない要素を `indexForTheOther` は共通の要素を示しそうな雰囲気がしてきましたね。ということは、、 `.symbolTableEntry`が `delete, insert`を、`indexForTheOther` が `move` になるのか？？
結論は一旦おいておきましょう。

Step-3では、`oldCounter == newCounter == .one` の場合のみ計算を行います。Heckelアルゴリズムでは、Counter { .zero, .one, .many } でした。.zeroは初期値だとして、.manyは無視するということは、配列内に一つしか無い要素、すなわちユニークな要素をうまく使って計算するということです。それでは、ユニークな要素に対して、`.symbolTableEntry` を `.indexForTheOther` に変えて行きましょう。

```swift
newElementEntries.enumerated().forEach { newIndex, element in
 guard case let .symbolTableEntry(entry) = element,
  entry.oldCounter == .one, entry.newCounter == .one else { return }

 let oldIndex = entry.indicesInOld.removeFirst()
 newElementEntries[newIndex] = .indexForTheOther(oldIndex)
 oldElementEntries[oldIndex] = .indexForTheOther(newIndex)
}
```
**本来、共通する２つの要素を見つけるためにはnewをループしてその中でoldをループ、またはその反対をする必要がありそうです。しかし、Heckelアルゴリズムでは共通のsymbolTable(キーはその要素)を持ち、そのentryとしてindicesInOldを持つことで片方のループだけで共通の要素を見つけられる様にしているわけです。(前者の様な方法の場合、計算量がO(NxM)となってしまうので、それを避けている点はとても重要かつ大きなポイントです。)**

Step-4に移りましょう。Step-3はユニークな要素に対してのみ、互いのインデックスを交換(.indexForTheOther)しました。しかし、ユニークでなくても、言い換えると複数の同じ要素でも2つの配列で共通部分を持つ場合はもちろん考えられますよね？ここでは、それを計算します。Step-3で計算した、ユニークな要素のインデックスを起点にして計算するわけです。
```swift
newElementEntries.enumerated().forEach { newIndex, element in
 guard newIndex < newElementEntries.count - 1,
  case let .indexForTheOther(oldIndex) = element, oldIndex < oldElementEntries.count - 1,
  case let .symbolTableEntry(newEntry) = newElementEntries[newIndex + 1],
  case let .symbolTableEntry(oldEntry) = oldElementEntries[oldIndex + 1],
  newEntry === oldEntry else { return }

 newElementEntries[newIndex + 1] = .indexForTheOther(oldIndex + 1)
 oldElementEntries[oldIndex + 1] = .indexForTheOther(newIndex + 1)
}
```
.symbolTableEntry(SymbolTableEntry)は配列O, Nで共通のsymbolTableから要素をキーとして得られるentryでした。
`newEntry === oldEntry`、すなわち、同じオブジェクトを参照しているかの条件によって同じ要素かどうか確かめています。
上の式で、 `.indexForTheOther` に変えられそうですね。

Step-5です。Step-4ではユニークな要素を起点にして、その次の要素を対象にしていました。しかし、ユニークな要素は疎らに存在していることも十分間が得られる訳です。つまり、その次の要素は勿論、その一つ前の要素に対しても同じことをする必要があります。Step-5ではそれを計算して行きます。
Step-4ではascending orderで問題ありませんが、Step-5ではdescending orderにすることに注意しましょう。
```swift
newElementEntries.enumerated().reversed().forEach { newIndex, element in
 guard newIndex > 0,
  case let .indexForTheOther(oldIndex) = item, oldIndex > 0,
  case let .symbolTableEntry(newEntry) = newElementEntries[newIndex - 1],
  case let .symbolTableEntry(oldEntry) = oldElementEntries[oldIndex - 1],
 newEntry === oldEntry else { return }

 newElementEntries[newIndex - 1] = .indexForTheOther(oldIndex - 1)
 oldElementEntries[oldIndex - 1] = .indexForTheOther(newIndex - 1)
}
```
さて、6つのStepの内、5つが完了しました。ここまでで、各配列で共通の要素・共通で無い要素が分かっています。先ほど少しだけ触れましたが、
- 共通で無い要素で配列Oに含まれているものは、配列Nに編集する(差分とはO -> Nの編集でした。)ためには削除しなければなりません。よって `delete`。
- 共通で無い要素で配列Nに含まれているものは、配列Oに加えなければなりません。よって `insert`。
- 共通要素の場合は、順番を変える編集が必要です。よって `move`。
Step-6では、これらの計算を行います。

```swift
enum Difference<E> {
 case delete(E, Int)
 case insert(E, Int)
 case move(E, Int, Int)
}

var differences: [Difference<E>] = []

oldElementEntries.enumerated().forEach { index, element in
 guard case .symbolTableEntry = element else { return }
 differences.append(.delete(oldArray[index], index))
}

newElementEntries.enumerated().forEach { index, element in
 guard case .symbolTableEntry = element else { return }
 differences.append(.insert(newArray[index], index))
}
```
この様な計算で、delete, insertのdiffが得られました。
次は、moveを計算しましょう。

.....(画像用意しなきゃ)
