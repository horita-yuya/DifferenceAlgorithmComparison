# DifferenceAlgorithmComparison
## Introduction
配列Aと配列Bの差分を取るということは、配列A -> 配列Bに編集していく作業だと考えることができます。
ここでいう編集とは、配列Aの要素を削除(delete)、配列Bの要素を追加(insert), 配列Aのi番目の要素を配列Bのj番目の要素に移動させる(move)、一連のこれらの作業のことを意味します。

## Wigner-Fischer
## Myers
## Wu

## Heckel
Introduction では配列A, Bとしていましたが、Heckelでは、慣習的にOldとNewの頭文字を使って配列O, 配列Nとします。
ある配列Oからある配列Nへの差分を取ることを考えましょう。

Heckel Algorithmでは、以下の様に3つのdata structureを考えます。
1. symbol table
2. old element references
3. new element references
まずsymbol tableから説明します。symbol tableは配列O, Nの各要素をkeyとするテーブルです。以下の様に実装的には、配列O, Nの各要素(のハッシュ値)をkey、symbol table entryをvalueとする辞書型のデータです。
symbol table entryは配列O, N内、それぞれのkey要素の数(カウンター)とkey要素の配列O内でのインデックス番号を持つ値です。カウンターは配列O, Nそれぞれに対して管理するので2つ必要で、インデックス番号と合わせると、symbol table entryは3つのプロパティを持つことになります。以下のコードのSymbolTableEntryがそれに該当します。
実は、このカウンターが持つ値としては 0, 1 or many(.zero, .one, .many)の3つだけを考えれば十分です。これは、Heckel Algorithmが配列O, Nそれぞれで重複しない要素、もしくはユニークな要素を起点として、差分を取ることを考えるからです。詳細については後ほどの [6-Steps](#6steps) で説明します。

```swift
let O: [Int] = [1, 2, 3, 3] // 1 and 2: unique, 3: not unique
let N: [Int] = [1, 2, 2, 3] // 1 and 3: unique, 2: not unique
```

カウンターに加えてもう一つ、`key要素の配列O内でのインデックス番号` がありますが、これはそのままの意味ですね。専門的には `OLNO` と呼ばれます。
```swift
<E: Hashable>

var symbolTable: [Int: SymbolTableEntry] = [:]

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
`1. symbol table` をまとめると、配列O, Nの各要素が全体で考えてどのくらいの数(Counter)含まれているのか？そして、それは配列Oのどこに(OLNO)含まれているのか？を管理するdata structureです。

それでは、`2, 3: old element references, new element references` についてです。まず前提として、これら2つは、配列O, Nの各要素と1:1対応する別の配列です。慣習的に配列OA, NAとします。`各要素と1:1対応する` とありますが、配列OA, NAにはそれぞれ、どのような値が入るのでしょうか。
今、元々の配列O, Nの要素の情報を持っているdata structureは、配列O, Nに加えて先ほどの `symbol table` (keyとして情報を持っている) がありますよね。`old, new element references`では、*自分自身以外* のdata structureの要素を参照して自分自身を再構成することを考えます。配列OA, NAにはその参照が格納されます。全体で3つある参照元の内自分自身以外を考えるので、参照元は `symbol table` と `もう片方の配列` の2つだけです。

```swift
enum ElementReference {
    case symbolTableEntry(SymbolTableEntry)
    case indexForTheOther(Int)
}
```

さて、一度ここまでの登場人物をまとめます。
- symbol table : 2つの配列O, Nの各要素をkeyとするtableで、その要素がそれぞれの配列に何個含まれてるのか。その要素が古い方の配列内で何番目のインデックスなのか。を管理。
  - symbol table entry: key-valueのvalue
- Old
  - O: 配列 (oldArray)
  - OA: ElementReferenceを管理する配列 (oldElementReferences)
- New
  - N: 配列 (newArray)
  - NA: ElementReferenceを管理する配列 (newElementReferences)

()内はswift化した時の変数名とします。
これ以降、新しい変数は登場せず、これらの変数を組み合わせて行くことで差分を取ることが出来ます。差分を取るまでに6つのStepが必要であり、この手順がHeckelの差分アルゴリズムです。

### <a name="6steps"> 6-Steps
それでは、1-6 Stepの内 Step-1から見て行きましょう。
```
1. 配列Nの各要素をキーとして、symbol table entryを作成。(ただし、そのキーのentryが存在している時は、そのentryを渡す。)
2. その要素のnewCounterをインクリメントする
3. NA[i]にsymbol table entryをセットする。(iはその要素のインデックス)
4. symbol tableに[key: value] = [N[i], NA[i]]として、entryを登録する。
```
Step-1は比較前の準備と言ったところです。
```swift
newArray.forEach {
    let entry = symbolTable[$0.hashValue] ?? SymbolTableEntry()
    entry.newCounter.increment()
    newElementReferences.append(.symbolTableEntry(entry))
    symbolTable[$0.hashValue] = entry
}
```
Step-2はStep-1と同じ操作をOldに対して行うだけです。ただし、Oldの場合、SymbolTableEntry.indicesInOldの管理も必要でしたね。
```swift
oldArray.enumerated().forEach { index, element
    let entry = symbolTable[element.hashValue] ?? TableEntry()
    entry.oldCounter.increment()
    entry.indicesInOld.append(index)
    oldElementReferences.append(.symbolTableEntry(entry))
    symbolTable[element.hashValue] = entry
}
```
すでに、6つの内、2つのStepが完了しました。

これからStep-3, 4, 5に移ります。この3つのStepを大まかに説明すると、Step-1, 2では `newElementReferences, oldElementReferences` に `.symbolTableEntry`だけを登録していました。これは比較のための準備で、一旦全て `symbol table` を参照させていただけです。これから、それらを可能な限り `indexForTheOther` に変えて行きます。つまり、もう片方の配列に参照を変えるということです。しかし、その要素がもう片方の配列に存在していなければ、参照はできません。その場合はそのまま `symbol table`を参照したままにします。

そうなると、最終的には `.symbolTableEntry` は共通で持たない要素を `indexForTheOther` は共通の要素を示しそうな雰囲気がします。ということは、、 `.symbolTableEntry`が `delete, insert`を、`indexForTheOther` が `move` になるのか？？結論は一旦おいておきましょう。

Step-3では、`oldCounter == newCounter == .one` の場合のみ計算を行います。Heckelアルゴリズムでは、Counter { .zero, .one, .many } でした。.zeroは初期値だとして、.manyは無視するということは、配列内に一つしか無い要素、すなわちユニークな要素をうまく使って計算するということです。それでは、ユニークな要素に対して、`.symbolTableEntry` を `.indexForTheOther` に変えて行きましょう。

```swift
newElementReferences.enumerated().forEach { newIndex, reference in
    guard case let .symbolTableEntry(entry) = reference,
        entry.oldCounter == .one,
        entry.newCounter == .one else { return }

    let oldIndex = entry.indicesInOld.removeFirst()
    newElementReferences[newIndex] = .indexForTheOther(oldIndex)
    oldElementReferences[oldIndex] = .indexForTheOther(newIndex)
}
```
**本来、共通する２つの要素を見つけるためには配列Nをループしてその中で配列Oをループ、またはその反対をする必要がありそうです。しかし、Heckelアルゴリズムでは2つの配列で共通のsymbolTable(keyは各要素)を持ち、そのvalue内でindicesInOldを持つことで片方のループだけで共通の要素を見つけられる様にしているわけです。(前者の様な方法の場合、計算量がO(NxM)となってしまうので、それを避けている点はとても重要かつ大きなポイントです。)**

Step-4に移りましょう。Step-3はユニークな要素に対してのみ、参照元を`symbol table`から`the other array`に変えました。しかし、ユニークでなくても、もしくは被った要素でも2つの配列で共通部分を持つ場合はもちろん考えられますよね？ここでは、それを計算します。Step-3で計算した、ユニークな要素のインデックスを起点にして計算するわけです。
```swift
newElementReferences.enumerated().forEach { newIndex, reference in
    guard case let .indexForTheOther(oldIndex) = reference, oldIndex < oldElementEntries.count - 1, newIndex < newElementEntries.count - 1,
        case let .symbolTableEntry(newEntry) = newElementEntries[newIndex + 1],
        case let .symbolTableEntry(oldEntry) = oldElementEntries[oldIndex + 1],
        newEntry === oldEntry else { return }

    newElementReferences[newIndex + 1] = .indexForTheOther(oldIndex + 1)
    oldElementReferences[oldIndex + 1] = .indexForTheOther(newIndex + 1)
}
```
.symbolTableEntry(SymbolTableEntry)は配列O, Nで共通のsymbolTableへのreferenceで、`symbol table`からは要素をkeyとして得られました。
つまり、`newEntry === oldEntry`、すなわち、entryが同じオブジェクトであればそのreferenceは同じ要素となります。
上の式で、無事に `.indexForTheOther` に変えられそうですね。

Step-5です。Step-4ではユニークな要素を起点にして、その次の要素を対象にしていました。しかし、ユニークな要素は疎らに存在していることも十分考えられる訳です。その次の要素は勿論、その一つ前の要素に対しても同じことをする必要があります。Step-5ではそれを計算して行きます。
Step-4ではascending orderで問題ありませんが、Step-5ではdescending orderにすることに注意しましょう。
```swift
newElementReferences.enumerated().reversed().forEach { newIndex, reference in
    guard case let .indexForTheOther(oldIndex) = reference, oldIndex > 0, newIndex > 0,
        case let .symbolTableEntry(newEntry) = newElementEntries[newIndex - 1],
        case let .symbolTableEntry(oldEntry) = oldElementEntries[oldIndex - 1],
        newEntry === oldEntry else { return }

    newElementReferences[newIndex - 1] = .indexForTheOther(oldIndex - 1)
    oldElementReferences[oldIndex - 1] = .indexForTheOther(newIndex - 1)
}
```
さて、6つのStepの内、5つが完了しました。ここまでで、配列O, Nに対応した配列OA, NAが決定されました。配列OA, NA内の各referenceが `symbol table`を指しているのか、`もう片方の配列`を指しているのかによって、*共通の要素・共通で無い要素を判別することができます。* 先ほど少しだけ触れましたが、
- 共通で無い要素で配列Oに含まれているものは、配列Nに編集するためには削除しなければなりません。よって `delete`。
- 共通で無い要素で配列Nに含まれているものは、配列Oに加えなければなりません。よって `insert`。
- 共通要素の場合は、順番を変える編集が必要です。よって `move`。
Step-6では、これらの計算を行います。

```swift
enum Difference<E> {
    case delete(element: E, index: Int)
    case insert(element: E, index: Int)
    case move(element: E, fromIndex: Int, toIndex: Int)
}

var differences: [Difference<T>] = []

oldElementReferences.enumerated().forEach { oldIndex, reference in
    guard case .symbolTableEntry = reference else { return }
    differences.append(.delete(element: oldArray[oldIndex], index: oldIndex))
}

newElementReferences.enumerated().forEach { newIndex, reference in
    switch reference {
        case .symbolTableEntry:
            differences.append(.insert(element: newArray[newIndex], index: newIndex))

        case .indexForTheOther(let oldIndex):
            differences.append(.move(element: newArray[newIndex], fromIndex: oldIndex, toIndex: newIndex))
    }
}
```
共通でなければ`symbol table`を参照するしかなく、共通であれば`もう片方の配列`を参照するので、この様な計算で、delete, insert, moveのdiffが得られます。
ここで、moveに関しては注意が必要です。元々の配列Oの各要素に対応して、配列OAがありました。もし配列Oと配列Nが同じであった場合、この配列は全てが  `.indexForTheOther` になります。これをそのまま `move` としてしまうと、あるインデックスから同じインデックスにmoveするという冗長なコマンドになってしまいます。これはあまり嬉しくないですね。その冗長なmoveを無くすことを考えましょう。

.....(画像用意しなきゃ)
