const Todo = require('../models/todo');

exports.getAllTodos = () => Todo.find();
exports.getTodoById = (id) => Todo.findById(id);
exports.createTodo = (data) => Todo.create(data);
exports.updateTodo = (id, data) => Todo.findByIdAndUpdate(id, data, { new: true });
exports.deleteTodo = (id) => Todo.findByIdAndDelete(id);