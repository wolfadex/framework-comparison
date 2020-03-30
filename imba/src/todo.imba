export class TodoItem
	prop title
	prop done

	def initialize title
		@title = title
		@done = no


export tag Todo
	def render
		<self>
			<li> <child>