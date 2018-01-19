# DifferenceAlgorithmComparison
# Introduction
配列Aと配列Bの差分を取るということは、配列A -> 配列Bに編集していく作業だと考えることができます。
ここでいう編集とは、配列Aの要素を削除(delete)、配列Bの要素を追加(insert), 配列Aのi番目の要素を配列Bのj番目の要素に移動させる(move)、一連のこれらの作業のことを意味します。

# Wigner-Fischer
# Myers & Wu
Introductionにある通り、配列Aと配列Bの差分を取るということは、元の配列Aから配列Bへ編集すると考えることが出来ます。また、Myers, Wu Alrogorithmにおいて編集とは、配列の要素をdelete, insertすることと等価です。例として以下のような配列を考えてみましょう。
```swift
enum Alphabet {
 case a, b, c
}

let A: [Alphabet] = [.a, .b, .c, .a, .b, .b, .a]
let B: [Alphabet] = [.c, .b, .a, .b, .a, .c]
```
配列A, Bを見比べながら差分を取っていくと、
1. A[0]は.cではなく、.aがある - delete A[0]
2. .aを削除すると、.bが先頭になるが.cではない - delete A[1]
3. 配列Aで.cが先頭に来た。その次には.bが合ってほしい - insert B[1] to A[2]
4. すると、先頭から.c .b .a .bとなり、その次が.bなので - delete A[5]
5. 先頭から.c .b .a .b .a隣、その次の.cが合ってほしい - insert B[5] to A[6]

\- の横には、行いたい編集作業をinsert, deleteのコマンドを使用して書いています。deleteやinsertを配列に対して行うと、要素のインデックスがずれてしまいますが、ここではインデックスは常に編集前の元の配列を指しているという定義にします。
また、insert B[j] to A[i] は、配列Bの要素B[j]を配列Aの要素A[j]の直後に挿入するという操作を示しています。

# Heckel
Introduction では配列A, Bとしていましたが、Heckelでは、慣習的にOldとNewの頭文字を使って配列O, 配列Nとします。
ある配列Oからある配列Nへの差分を取ることを考えましょう。

Heckel Algorithmでは、以下の様に3つのdata structureを考えます。
1. symbol table
2. old element references
3. new element references

まずsymbol tableから説明します。symbol tableは配列O, Nの各要素をkeyとするテーブルです。以下の様に実装的には、配列O, Nの各要素(のハッシュ値)をkey、symbol table entryをvalueとする辞書型のデータです。

symbol table entryは配列O, N内、**それぞれのkey要素の数(カウンター)**と**key要素の配列O内でのインデックス**を持つ値です。カウンターは配列O, Nそれぞれに対して管理するので2つ必要で、インデックスと合わせると、symbol table entryは3つのプロパティを持つことになります。以下のコードのSymbolTableEntryがそれに該当します。

実は、このカウンターが持つ値としては  *0, 1 or many(.zero, .one, .many)* の3つだけを考えれば十分です。これは、Heckel Algorithmが配列O, Nそれぞれで重複しない要素、もしくはユニークな要素を起点として、差分を取ることを考えるからです。詳細については後ほどの [6-Steps](#6steps) で説明します。

```swift
let O: [Int] = [1, 2, 3, 3] // 1 and 2: unique, 3: not unique
let N: [Int] = [1, 2, 2, 3] // 1 and 3: unique, 2: not unique
```

カウンターに加えてもう一つ、`key要素の配列O内でのインデックス` がありますが、これはそのままの意味ですね。専門的には `OLNO` と呼ばれます。
さらに、この `OLNO` は、カウンターが.oneの場合のみ必要です。

```swift
<E: Hashable>

var symbolTable: [Int: SymbolTableEntry] = [:]

enum Counter {
    case zero
    case one(index: Int) // OLNO
    case many

    mutating func increment(withIndex index: Int) {
        switch self {
            case .zero:
                self = .one(index: index)
                
            default:
                self = .many
        }
    }
}

class SymbolTableEntry {
    var oldCounter: Counter
    var newCounter: Counter
}
```
`1. symbol table` をまとめると、**配列O, Nの各要素が全体で考えてどのくらいの数(Counter)含まれているのか？そして、それは配列Oのどこに(OLNO)含まれているのか？を管理するdata structureです。**

それでは、`2, 3: old element references, new element references` についてです。まず前提として、これら2つは、配列O, Nの各要素と`1:1対応する`別の配列です。慣習的に配列OA, NAとします。`各要素と1:1対応する` とありますが、配列OA, NAにはそれぞれ、どのような値が入るのでしょうか。

今、元々の配列O, Nの要素の情報を持っているdata structureは、配列O, Nに加えて先ほどの `symbol table` (keyとして情報を持っている) がありますよね。`old, new element references`では、**自分自身以外のdata structureの要素を参照して自分自身を再構成すること**を考えます。

配列OA, NAにはその参照が格納されます。全体で3つある参照元の内、自分自身以外を考えるので、参照元は `.symbolTable` と `.theOther` の2つだけです。実装的には以下のようになります。

```swift
enum ElementReference {
    case symbolTable(entry: SymbolTableEntry)
    case theOther(index: Int)
}
```

さて、一度ここまでの登場人物をまとめます。
- symbol table :
  - 2つの配列O, Nの各要素をkeyとする辞書型データ
  - 配列O, Nで共通
  - symbol table entry: key-valueのvalueを管理
    - その要素がそれぞれの配列に何個含まれてるのか。
    - その要素が古い方の配列O内で何番目のインデックスなのか。
- Old
  - O: 配列 (oldArray)
  - OA: ElementReferenceを管理する配列 (oldElementReferences)
- New
  - N: 配列 (newArray)
  - NA: ElementReferenceを管理する配列 (newElementReferences)

()内はswift化した時の変数名とします。
これ以降、他の登場人物は登場せず、これらを`うまく組み合わせて`行くことで差分を取ることが出来ます。差分を取るまでに6つのStepが必要であり、`うまく組み合わせる`工夫とこの手順がHeckel Algorithmの核です。

## <a name="6steps"> 6-Steps

### Step-1

それでは、1-6 Stepの内 Step-1から見て行きましょう。手順は以下の通りです。
```
1. 配列Nの各要素をキーとして、symbol table entryを作成。(ただし、そのキーのentryが存在している時は、そのentryを渡す。)
2. その要素のnewCounterをインクリメントする
3. NA[i]に.symbolTable(entry:)をセットする。(iはその要素のインデックス)
4. symbol tableに[key: value] = [N[i], NA[i]]として、entryを登録する。
```
Step-1は比較前の準備と言ったところです。
```swift
newArray.forEach { element in
    let entry = symbolTable[element.hashValue] ?? SymbolTableEntry()
    entry.newCounter.increment(withIndex: 0)
    newElementReferences.append(.symbolTable(entry: entry))
    symbolTable[element.hashValue] = entry
}
```
ここで、withIndex: 0としているのは、SymbolTableEntryが管理するインデックスは、配列Oに対して管理すれば十分なので配列Nに対しては0を代入しています。

### Step-2

Step-2はStep-1と同じ操作をOldに対して行うだけです。ただし、Oldの場合、SymbolTableEntry.indicesInOldの管理も必要でしたね。
```swift
oldArray.enumerated().forEach { index, element
    let entry = symbolTable[element.hashValue] ?? TableEntry()
    entry.oldCounter.increment(withIndex: index)
    oldElementReferences.append(.symbolTable(entry: entry))
    symbolTable[element.hashValue] = entry
}
```
すでに、6つの内、2つのStepが完了しました。

これからStep-3, 4, 5に移りますが、その前にこの3つのStepを大まかに説明します。

Step-1, 2では `newElementReferences, oldElementReferences` に `.symbolTable`だけを登録していました。これは一旦全て `.symbolTable` を参照させることで、配列の比較のための準備をしているのです。

これから、それらの参照を可能な限り `.theOther` に変えて行きます。つまり、symbol tableからもう片方の配列に参照を変えるということです。しかし、その要素がもう片方の配列に存在していなければ、参照はできません。その場合はそのまま `.symbolTable`を参照したままにします。

そうなると、最終的には `.symbolTable` は共通で持たない要素を `.theOther` は共通の要素を示しそうな雰囲気がします。ということは、、 `.symbolTable`が `delete, insert`を、`.theOther` が `move` になるのか？？結論は一旦おいておきましょう。

### Step-3

Step-3では、`oldCounter == newCounter == .one` の場合のみ計算を行います。

Heckelアルゴリズムでは、Counter { .zero, .one, .many } でした。.zeroは初期値だとして、.manyは無視するということは、先ほど出てきた `ユニークな要素`をうまく使って計算するということです。`oldCounter == newCounter == .one` の条件は、各配列でそのユニークな要素がただ一つの共通要素になっていることになります。

それでは、ユニークな要素に対して参照先を`.symbolTable` から `.theOther` に変えて行きましょう。

```swift
newElementReferences.enumerated().forEach { newIndex, reference in
    guard case let .symbolTable(entry: entry) = reference,
        case .one(let oldIndex) = entry.oldCounter,
        case .one = entry.newCounter else { return }

    newElementReferences[newIndex] = .theOther(index: oldIndex)
    oldElementReferences[oldIndex] = .theOther(index: newIndex)
}
```
**本来、共通する２つの要素を見つけるためには配列Nをループしてその中で配列Oをループ、またはその反対をする必要がありそうです。しかし、Heckelアルゴリズムでは2つの配列で共通のsymbolTable(keyは各要素)を持ち、そのvalue内でindicesInOldを持つことで、片方のループだけで共通の要素を見つけられる様にしているわけです。(前者の様な方法の場合、計算量がO(NxM)となってしまうので、それを避けている点はとても重要かつ大きなポイントです。)**

### Step-4

Step-4に移りましょう。Step-3はユニークな要素に対してのみ、参照元を`.symbolTable`から`.theOther`に変えました。しかし、ユニークでなくても、もしくは被った要素でも2つの配列で共通部分を持つ場合はもちろん考えられますよね？ここでは、それを計算します。Step-3で計算した、ユニークな要素のインデックスを起点にして計算するわけです。
```swift
newElementReferences.enumerated().forEach { newIndex, reference in
    guard case let .theOther(index: oldIndex) = reference, oldIndex < oldElementReferences.count - 1, newIndex < newElementReferences.count - 1,
        case let .symbolTable(entry: newEntry) = newElementReferences[newIndex + 1],
        case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex + 1],
        newEntry === oldEntry else { return }

    newElementReferences[newIndex + 1] = .theOther(index: oldIndex + 1)
    oldElementReferences[oldIndex + 1] = .theOther(index: newIndex + 1)
}
```
.symbolTable(entry: SymbolTableEntry)は配列O, Nで共通のsymbolTableへの参照で、このassociated valueのSymbolTableEntryは`symbol table`からは要素をkeyとして得られました。
つまり、`newEntry === oldEntry`、すなわち、entryが同じオブジェクトであればそのreferenceは同じ要素を指していることになります。
上の式で、無事に参照先を `.theOther` に変えられそうですね。

### Step-5

Step-5です。Step-4ではユニークな要素を起点にして、その次の要素を対象にしていました。しかし、ユニークな要素は疎らに存在していることも十分考えられる訳です。その次の要素は勿論、その一つ前の要素に対しても同じことをする必要があります。Step-5ではそれを計算して行きます。
Step-4ではascending orderで問題ありませんが、Step-5ではdescending orderにすることに注意しましょう。
```swift
newElementReferences.enumerated().reversed().forEach { newIndex, reference in
    guard case let .theOther(index: oldIndex) = reference, oldIndex > 0, newIndex > 0,
        case let .symbolTable(entry: newEntry) = newElementReferences[newIndex - 1],
        case let .symbolTable(entry: oldEntry) = oldElementReferences[oldIndex - 1],
        newEntry === oldEntry else { return }

    newElementReferences[newIndex - 1] = .theOther(index: oldIndex - 1)
    oldElementReferences[oldIndex - 1] = .theOther(index: newIndex - 1)
}
```
さて、6つのStepの内、5つが完了しました。

### Step-6

ここまでで、配列O, Nに対応した配列OA, NAが決定されました。配列OA, NA内の各referenceが `.symbolTable`を指しているのか、`.theOther`を指しているのかによって、*共通の要素・共通で無い要素を判別すること*ができます。 先ほど少しだけ触れましたが、
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
    guard case .symbolTable = reference else { return }
    differences.append(.delete(element: oldArray[oldIndex], index: oldIndex))
}

newElementReferences.enumerated().forEach { newIndex, reference in
    switch reference {
        case .symbolTable:
            differences.append(.insert(element: newArray[newIndex], index: newIndex))

        case let .theOther(index: oldIndex):
            differences.append(.move(element: newArray[newIndex], fromIndex: oldIndex, toIndex: newIndex))
    }
}
```
共通でなければ`.symbolTable`を参照するしかなく、共通であれば`.theOther`を参照します。よって、この様な計算で、delete, insert, moveのdiffが得られます。

ここで、moveに関しては注意が必要です。元々の配列Oの各要素に対応して、配列OAがありました。もし配列Oと配列Nが同じであった場合、この配列は全ての参照先が  `.theOther` になります。これをそのまま `move` としてしまうと、あるインデックスから同じインデックスにmoveするという冗長なコマンドになってしまいます。これはあまり嬉しくないですね。その冗長なmoveを無くすことを考えましょう。
