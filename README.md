# PythontexProfiler.jl

This package is a profiler for the pythontex package when used to produce Julia code. It is useful for determining what lines of code in a latex document are responsible for computation time, memory allocation, and garbage collection.

## Example

We have a tex file [test.tex](test/test.tex):
```latex
\documentclass{article}

\usepackage[usefamily={jl,julia,juliacon}]{pythontex}

\begin{document}

\begin{jlcode}
a = rand(300,300)
\end{jlcode}

\input{test2.tex}

\end{document}
```
This tex file inputs another tex file [test2.tex](test/test2.tex) that does some more computation:
```latex
This is the second tex file.

\begin{jlcode}
b = sin.(a)
a += rand(300,300)
\end{jlcode}

\begin{equation}
V(s) \max_a [R(s, a) + \gamma \sum_{s'} T(s' \mid s, a) V(s')]
\end{equation}

\begin{jlcode}
a += exp.(a)
\end{jlcode}

\begin{jlcode}
let
    x = 5.0
    for i = 1:100000
        x += sum(sin.(rand(30)))
    end
end
\end{jlcode}
```
We run `pdflatex test` on the main `test.tex` document. It will produce [test.pytxcode](test/test.pytxcode) containing the Julia code. We can then profile this resulting document:
```
$ julia -e 'using PythontexProfiler; profile("test.pytxcode")'
Running :7
Running test2.tex:3
Running test2.tex:12
Running test2.tex:16
┌───────────┬──────┬─────────────┬──────────┬───────────┐
│      file │ line │        time │    bytes │    gctime │
├───────────┼──────┼─────────────┼──────────┼───────────┤
│ test2.tex │    3 │ 0.506897701 │ 54188360 │ 0.0323643 │
│           │    7 │   0.3651535 │ 58521288 │ 0.0240292 │
│ test2.tex │   16 │   0.2590418 │ 82040295 │  0.032396 │
│ test2.tex │   12 │   0.0862714 │ 13105454 │       0.0 │
└───────────┴──────┴─────────────┴──────────┴───────────┘
```
