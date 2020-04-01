import karax / [vdom, karax, karaxdsl, jstrutils, compact, localstorage]
import options
import sequtils
import times, os

func jslog(argument: cstring) {.importjs: """ console.log(#) """.}

type
  Filter = enum
    all, active, completed


type
  Todo* = object
    content*: cstring
    completed: bool
    uuid: int64

var
  selectedEntry = -1
  todoFilter: Filter
  entriesLen: int
  doneswitch = true
  todos: seq[Todo] = @[]
const
  contentSuffix = cstring"content"
  todoKey = cstring"wolfadex__fc__nim-karax__todo"



proc stringifyTodo(todo: Todo): cstring =
    todo.content & "__" & (if todo.completed: "true" else: "false") & "__" & $todo.uuid

proc saveTodos() =
  setItem(&todoKey, todos.map(stringifyTodo).foldl(a & ";;" & b))


proc findTodo(uuid: int64): Option[Todo] =
  try:
    some(todos.filterIt(it.uuid == uuid)[0])
  except:
    none(Todo)


proc isCompleted(id: int64): bool =
  try:
    get(findTodo(id)).completed
  except:
    false

proc setEntryContent(pos: int, content: cstring) =
  setItem(&pos & contentSuffix, content)

proc markAsCompleted(id: int64, completed: bool) =
  todos = todos.map(proc (todo: Todo): Todo =
    Todo(content: todo.content,
        uuid: todo.uuid,
        completed: if todo.uuid == id: completed else: todo.completed))
  saveTodos()

proc parseTodo(maybeTodo: cstring): Option[Todo] =
  let t = maybeTodo.split("__")
  try:
    some(Todo(content: t[0],
         completed: t[1] == "true",
         uuid: parseInt(t[2])))
  except:
    none(Todo)

proc addEntry(content: cstring, completed: bool) =
  todos.insert(Todo(content: content,
                    completed: completed,
                    uuid: getTime().toUnix()))
  saveTodos()

proc updateEntry(id: int64, content: cstring, completed: bool) =
  # setEntryContent(id, content) TODO
  markAsCompleted(id, completed)

proc onTodoEnter(ev: Event; n: VNode) =
  if n.value.strip() != "":
    addEntry(n.value, false)
    n.value = ""

proc removeHandler(ev: Event; n: VNode) =
  updateEntry(n.index, cstring(nil), false)

proc editHandler(ev: Event; n: VNode) =
  selectedEntry = n.index

proc focusLost(ev: Event; n: VNode) = selectedEntry = -1

proc editEntry(ev: Event; n: VNode) =
  # setEntryContent(n.index, n.value) TODO
  selectedEntry = -1

proc toggleEntry(id: int64): proc(ev: Event; n: VNode) =
  result = proc (ev: Event; n: VNode) =
    jslog("carl_" & $id)
    markAsCompleted(id, not isCompleted(id))

proc onAllDone(ev: Event; n: VNode) =
  for i in 0..<entriesLen:
    markAsCompleted(i, doneswitch)
  doneswitch = not doneswitch
proc clearCompleted(ev: Event, n: VNode) =
  for i in 0..<entriesLen:
    if isCompleted(i): setEntryContent(i, nil)

proc toClass(completed: bool): cstring =
  (if completed: cstring"completed" else: cstring(nil))

proc selected(v: Filter): cstring =
  (if todoFilter == v: cstring"selected" else: cstring(nil))

proc createEntry(id: int64; d: cstring; completed, selected: bool): VNode {.compact.} =
  result = buildHtml(tr):
    li(class=toClass(completed)):
      if not selected:
        tdiv(class = "view"):
          input(class = "toggle", `type` = "checkbox", checked = toChecked(completed),
                onclick=toggleEntry(id), index=id)
          label(onDblClick=editHandler, index=id):
            text d
          button(class = "destroy", index=id, onclick=removeHandler):
            text "delete"
      else:
        input(class = "edit", name = "title", index=id,
          onblur = focusLost,
          onkeyupenter = editEntry, value = d, setFocus=true)

proc makeFooter(entriesCount, completedCount: int): VNode =
  result = buildHtml(footer(class = "footer")):
    span(class = "todo-count"):
      strong:
        text(&entriesCount)
      text cstring" item" & &(if entriesCount != 1: "s left" else: " left")
    ul(class = "filters"):
      li:
        a(class = selected(all), href = "#/"):
          text "All"
      li:
        a(class = selected(active), href = "#/active"):
          text "Active"
      li:
        a(class = selected(completed), href = "#/completed"):
          text "Completed"
    button(class = "clear-completed", onclick = clearCompleted):
      text "Clear completed (" & &completedCount & ")"

proc makeHeader(): VNode {.compact.} =
  result = buildHtml(header(class = "header")):
    h1:
      text "todos"
    input(class = "new-todo", placeholder="What needs to be done?", name = "newTodo",
          onkeyupenter = onTodoEnter, setFocus)

proc createDom(data: RouterData): VNode =
  if data.hashPart == "#/": todoFilter = all
  elif data.hashPart == "#/completed": todoFilter = completed
  elif data.hashPart == "#/active": todoFilter = active
  result = buildHtml(tdiv(class="todomvc-wrapper")):
    section(class = "todoapp"):
      makeHeader()
      section(class = "main"):
        input(class = "toggle-all", `type` = "checkbox", id = "toggle", onclick = onAllDone)
        label(`for` = "toggle"):
          text "Mark all as complete"
        var entriesCount = 0
        var completedCount = 0
        ul(class = "todo-list"):
          for todo in todos:
            let b = case todoFilter
                    of all: true
                    of active: not todo.completed
                    of completed: todo.completed
            if b:
              createEntry(todo.uuid, todo.content, todo.completed, todo.uuid == selectedEntry)
            inc completedCount, ord(todo.completed)
            inc entriesCount
      makeFooter(entriesCount, completedCount)

proc filterOptionalTodos(t: Option[Todo]): bool =
  try:
    let _ = get(t)
    true
  except:
    false

type
  MyCustomError* = object of Exception

proc extractTodo(t: Option[Todo]): Todo =
  try:
    get(t)
  except:
    raise newException(MyCustomError, "How did we get here?")

if hasItem(todoKey):
  todos =
    getItem(todoKey)
      .split(";;")
      .map(parseTodo)
      .filter(filterOptionalTodos)
      .map(extractTodo)
else:
  todos = @[]

setRenderer createDom, "root"