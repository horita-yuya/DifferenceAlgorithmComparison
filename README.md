# Heckel
ある配列Oからある配列Nへの差分を取ることを考えましょう。

Heckel Algorithmでは、以下の様に3つのdata structureを考えます。
1. symbol table
2. old element references
3. new element references

まずsymbol tableから説明します。symbol tableは配列O, Nの各要素をkeyとするテーブルです。以下の様に実装的には、配列O, Nの各要素(のハッシュ値)をkey、symbol table entryをvalueとする辞書型のデータです。
要素をKeyとしますので、同じ要素であれば、同じValueが返ってきます。そのため、symbol tableは、全登場人物を管理するdata structureとなります。

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
これ以降、他の登場人物は登場せず、これらを`うまく組み合わせて`行くことで差分を取ることが出来ます。差分を取るまでに6つのStepが必要であり、その組み合わせ方と手順がHeckel Algorithmの核です。

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
newElementReferences.enumerated().forEach { newIndex, _ in
  guard case let .theOther(index: oldIndex) = newElementReferences[newIndex],
    oldIndex < oldElementReferences.count - 1, newIndex < newElementReferences.count - 1,
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
newElementReferences.enumerated().reversed().forEach { newIndex, _ in
  guard case let .theOther(index: oldIndex) = newElementReferences[newIndex],
    oldIndex > 0, newIndex > 0,
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



#  Myers Difference Algorithm

Myers Difference Algorithm is an algorithm that finds a longest common subsequence(LCS) or shortest edit scripts(SES) of two sequences. MDA can accomplish this in O(ND) time, where N is the sum of the lengths of the two sequences. The common subsequence of two sequences is the sequence of elements that appear in the same order in both sequences.

For example, let's assume you have two arrays:

```
A = [1, 2, 3]
B = [2, 3, 4]
```

The common subsequences of these two arrays are `[2]`, and `[2,3]`. The longest common sequence in this case is `[2,3]`.

## Finding the length of the Longest Common Subsequence with Myers Algorithm on Edit Graph

### Edit Graph

MDA uses an **Edit Graph** to solve the LCS/SES problem. Below is a illustration depicting an edit graph:

<img src='Images/EditGraph.png' height="400">

The x-axis at the top of the graph represents one of the sequences, `X`. The y-axis at the left side of the graph represents the other sequence, `Y`. Hence, the two sequences in question is the following:

```
X = [A, B, C, A, B, B, A]
Y = [C, B, A, B, A, C]
```

MDA generates the edit graph through the following steps:

1. Line the element of sequence `X` on the x axis. And do for `Y` on the y axis.
2. Make grid and vertex at each point in the grid (x, y), `x in [0, N] and y in [0, M]`. `N` is the length of sequence `X`, `M` is of `Y`
3. Line for `x - y = k`, this line called k-line.
4. Check the points `(i, j)`, where `X[i] = Y[j]`, called match point.
5. Connect vertex `(i - 1, j - 1)` and vertex `(i, j)`, where `(i, j)` is match point, then diagonal edge appears.

Each elements on the figure shows that,
- `Red number and dotted lines`: The red number is the value of k and dotted lines are k-line.
- `Green dots: The match points`, which is the point `(i, j)` where `X[i] == Y[j]`
- `Blue line`: The shortest path from source to sink, which is the path we are going to find finally.

> **Note:** Here, the sequences' start index is 1 not 0, so `X[1] = A`, `Y[1] = C`

We discuss about which path is the shortest from `source` to `sink`. Can move on the edges on the graph. I mean we can move on  the grid, horizontal and vertical edges, and the diagonal edges.

The movements are compatible with the `Edit Scripts`, insert or delete. The word `Edit Scripts` appeared here, as referred at Introduction, SES is Shortest Edit Scripts.

Let's get back on track. On this edit graph, the horizontal movement to vertex `(i, j)` is compatible with the script  `delete at index i from X`, the vertical movement to vertex `(i, j)` is compatible with the script `insert the element of Y at index j to immediately after the element of X at index i`. How about for the diagonal movement?. This movement to vertex `(i, j)` means `X[i] = Y[j]`, so no script needs.

- horizontal movement -> delete
- vertical movement -> insert
- diagonal movement -> no script because both are same.

Next, add cost 1 for non-diagonal movement, because they can be compatible with script. And 0 for diagonal movement, same means no script.

The total cost for the minimum path, exploring from `source` to `sink`, is the same as the length of the Longest Common Subsequence or Shortest Edit Script.

So, LCS/SES problem can be solved by finding the shortest path from `source` to `sink`.

# Myers Algorithm

As mentioned above, the problem of finding a shortest edit script can be reduced to finding a path from `source (0, 0)` to `sink (N, M)` with the fewest number of horizontal and vertical edges. Let `D-path` be a path starting at `source` that has exactly `D` non-diagonal edges, or must move non-diagonally D-times.

For example, A 0-path consists solely of diagonal edges. This means both sequences are completely same.

By a simple induction, D-path must consist of a (D-1)-path followed by a non-diagonal edge and then diagonal edges, which called `snake`. The minimum value of D is 0, both sequences being same. To the contrary, the maximum value of D is N + M because delete all elements from X and insert all elements from Y to X is the worst case edit scripts. For getting D, or the length of SES, running loop from 0 to N + M is enough.

```swift
for D in 0...N + M
```

Next, thinking about, where is the furthest reaching point for D-path on k-line. Like below, moving horizontally from k-line reaches (k+1)-line, moving vertically from k-line reaches (k-1)-line. Red chalky line shows that.

<img src='Images/EditGraph_k_move.png' height="400">

So, threre are several end points of D-path, or D-path can end on several k-line. We need the information to get the next path ((D+1)-path) as mentioned above. In fact, D-path must end on
k-line, where k in { -D, -D + 2, ....., D - 2, D }. This is so simple, starting point, `source` is `(0, 0)` on (k=0)-line. D is the number of non-diagonal edges and non-diagonal movement changes current k-line to (kpm1)-line. Because 0 is even number, if D is even number D-path will end on (even_k)-line, if D is odd number D-path will end on (odd_k)-line.

Searching loop outline will be below.

```swift
for D in 0...N + M {
  for k in stride(from: -D, through: D, by: 2) {
    //Find the end point of the furthest reaching D-path in k-line.
    if furthestReachingX == N && furthestReachingY == M {
      // The D-path is the shortest path
      // D is the length of Shortest Edit Script
      return
    }
  }
}
```

The D-path on k-line can be decomposed into
- a furthest reaching (D-1)-path on (k-1)-line, followed by a horizontal edge, followed by `snake`.
- a furthest reaching (D-1)-path on (k+1)-line, followed by a vertical edge, followed by `snake`.
as discussed above.

The Myers Algorithm key point are these.
- D-path must end on k-line, where k in { -D, -D + 2, ....., D - 2, D }
- The D-path on k-line can be decomposed into two patterns

thanks for these, the number of calculation become less.

```swift
public struct MyersDifferenceAlgorithm<E: Equatable> {
    public static func calculateShortestEditDistance(from fromArray: Array<E>, to toArray: Array<E>) -> Int {
        let fromCount = fromArray.count
        let toCount = toArray.count
        let totalCount = toCount + fromCount
        var furthestReaching = Array(repeating: 0, count: 2 * totalCount + 1)

        let isReachedAtSink: (Int, Int) -> Bool = { x, y in
            return x == fromCount && y == toCount
        }

        let snake: (Int, Int, Int) -> Int = { x, D, k in
            var _x = x
            while _x < fromCount && _x - k < toCount && fromArray[_x] == toArray[_x - k] {
                _x += 1
            }
            return _x
        }

        for D in 0...totalCount {
            for k in stride(from: -D, through: D, by: 2) {
                let index = k + totalCount

                // (x, D, k) => the x position on the k_line where the number of scripts is D
                // scripts means insertion or deletion
                var x = 0
                if D == 0 { }
                    // k == -D, D will be the boundary k_line
                    // when k == -D, moving right on the Edit Graph(is delete script) from k - 1_line where D - 1 is unavailable.
                    // when k == D, moving bottom on the Edit Graph(is insert script) from k + 1_line where D - 1 is unavailable.
                    // furthestReaching x position has higher calculating priority. (x, D - 1, k - 1), (x, D - 1, k + 1)
                else if k == -D || k != D && furthestReaching[index - 1] < furthestReaching[index + 1] {
                    // Getting initial x position
                    // ,using the furthestReaching X position on the k + 1_line where D - 1
                    // ,meaning get (x, D, k) by (x, D - 1, k + 1) + moving bottom + snake
                    // this moving bottom on the edit graph is compatible with insert script
                    x = furthestReaching[index + 1]
                } else {
                    // Getting initial x position
                    // ,using the futrhest X position on the k - 1_line where D - 1
                    // ,meaning get (x, D, k) by (x, D - 1, k - 1) + moving right + snake
                    // this moving right on the edit graph is compatible with delete script
                    x = furthestReaching[index - 1] + 1
                }

                // snake
                // diagonal moving can be performed with 0 cost.
                // `same` script is needed ?
                let _x = snake(x, D, k)

                if isReachedAtSink(_x, _x - k) { return D }
                furthestReaching[index] = _x
            }
        }

        fatalError("Never comes here")
    }
}
```
