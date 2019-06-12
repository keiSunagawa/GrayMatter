# Graymatter

GraymatterはElixir用のFreeMonadを利用して副作用を切り離すためのライブラリです  
FreeMonad自体はユーザから隠されていて、ユーザはDSLのための構造体の定義とそれのハンドラを  
定義するだけで使用できます  
このライブラリは [Algae](https://github.com/witchcrafters/algae) に依存します  

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `graymatter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:graymatter, "~> 0.1.0", git: "https://github.com/keiSunagawa/graymatter.git"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/gray_matter](https://hexdocs.pm/gray_matter).


## Usage
### コマンド  
副作用が発生するであろう関数のインタフェース  
`defcommand` macroによって定義し、インタフェース関数が自動生成されます  
```elixir
defmodule Console do
  import Graymatter.Command

  defcommand PutStrLn do
    value :: String.t()
    next :: any()
  end
  defcommand GetStr do
    next :: (String.t() -> any())
  end
end
```
コマンドは必ずnextメンバを持ちます、nextメンバは次の命令を格納するためのメンバです  
nextメンバは必ず以下の二種類のどちらかを定義します  
```elixirr
next :: any() # 戻り値を返さないコマンド

next :: (a -> any()) # コマンドによって a 型の戻り値が返る
```
`a -> any()` は後述のchain式によってaの値を取り出し、次のコマンドに渡したり、プログラムの戻り値として使用することができます  
`defcommand` によって定義した構造体と同名の関数が自動生成されます、ユーザはこれ使ってプログラムを組み立てます  

### プログラム  
コマンドによって生成された関数とchain式によってプログラムを組み立てることができます  
```elixir
chain do
  putstrln("Hello.")
  input <- getstr()
  putstrln(input)
end
```

プログラムは組み立てたタイミングでは実行されません、別途定義したハンドラによって実行されます  

また、プログラムは合成可能です  
```elixir
def program do
  chain do
    name <- request_name()
    put_for_n(name, 10)
  end
end

def request_name do
  chain do
    putstrln("please your name.")
    getstr()
  end
end

def put_for_n(str, n) do
  chain do
    putstrln(str)
    if (n == 0), do: putstrln("done."), else: put_for_n(str, n-1)
  end
end
```

### ハンドラ  
ハンドラを定義、呼び出すことによってプログラムを実行できます  
`defhandler` によって定義でき、コマンド構造体のパタンマッチを定義します  
```elixir
defhandler &Id.new/1 do
  %Console.PutStrLn{value: v, next: n} ->
    IO.inspect(v)
    Id.new(n)
  %Console.GetStr{next: nf} ->
    input = IO.gets(">> ")
    Id.new(nf.(input))
end
```

ハンドラの実態はFreeモナドから別のモナドへの変換関数です  
ユーザはその一部分のみを実装します  
`defhandler` によって自動生成される `interpreter` 関数に組み立てたプログラムを渡すことで実行することができます  
```elixir
interpreter(program())
```

---

より詳しい実装の例は [examples](examples/lib/) にあります
