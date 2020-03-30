import { TodoItem, Todo } from './todo'

tag App
	prop todos

	def addTodo
		const t =
			title: @newTodoTitle
			completed: false
			uuid: Date.new.getTime
		@todos.push t

	def render
		<self>
			<form.header :submit.prevent.addTodo>
				<input[@newTodoTitle] placeholder="Add...">
				<button type='submit'> 'Add item'
			<ul> for todo in @todos
				<Todo> todo['title']

Imba.mount <App.vbox todos=[]>