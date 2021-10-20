import express from 'express'
import mongoose from 'mongoose'
import session from 'express-session'
import MongoStore, { create } from 'connect-mongo'
import cors from 'cors'
import http from 'http'
import { Server } from 'socket.io'

import userController from './backend/controllers/user.controller'
import authController from './backend/controllers/authentication.controller'
import postController from "./backend/controllers/posts.controller"

require("dotenv").config();

const app = express()
const server = http.createServer(app)

app.use(express.urlencoded({ extended: true }))
app.use(express.json())
app.use(cors())

const PORT = process.env.PORT || 3001
const uri = `mongodb+srv://${process.env.MONGO}@merncluster.eacb3.mongodb.net/audite?retryWrites=true&w=majority`
const options = { useNewUrlParser: true, useUnifiedTopology: true }


mongoose.set("useFindAndModify", false)
mongoose
  .connect(uri, options)
  .then(() =>
    server.listen(PORT, () =>
      console.log(`Server running on http://localhost:${PORT}`)
    )
  )
  .catch(error => {
    throw error
  })

app.use(
  session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: true,
    store: MongoStore.create({ mongoUrl: uri, mongoOptions: options }),
    cookie: {
      maxAge: 1000 * 60 * 60 * 24
    }
  })
)

const io = new Server(server, {
  cors: {
    origin: "http://localhost:3000",
    methods: ["GET", "POST"],
    transports: ['websocket', 'polling'],
    allowedHeaders: ["Access-Control-Allow-Origin"],
    credentials: true
  },
  allowEIO3: true
})

/* https://stackoverflow.com/a/38259193 */
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS, POST, PUT");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
  next();
});
	// try {
	// 	let result = await io.in(rooms[0].id).fetchSockets()
	// 	// io.to(rooms[0].id).emit()§
	// } catch (error) {
	// console.log(error)
	// }

		// })

		socket.on('disconnect', () => {
			
		console.log('bye')
  })
})
  let rooms = [{id: 'aaa', users: []}, {id: 'bbb', users: []}]
app.get('/api/test', (req,res) => {
io.on('connection', async (socket) => {
	console.log('connected')
	socket.join('aaa')
	console.log(socket.rooms)
	try {
		let result = await io.in(rooms[0].id).fetchSockets()
		io.to('aaa').emit('userjoin', result)
	} catch(err) {
		return err
	}
  // if(!req.headers.authorization) throw(new Error('no auth'))
    // let user = res.locals.user
    // console.log(user)
	
  io.emit('hi')
  // res.sendFile(__dirname + '/public/connect.html')
})

/* Login/register routing */
app.post('/register', userController.register)
app.post('/login', authController.login)
app.get('/logout', authController.logout)

/* User routing */
app.get('/users', userController.userList)
app.get('/user/:username', userController.getProfile)
app.get('/user/id/:id', userController.userById)

/* Local user settings' routing with authentication middleware */
app.get('/settings', authController.authenticateToken, userController.getSettings)
app.post('/settings/delete', authController.authenticateToken, userController.delete)

/* Local user post routing with authentication middleware */
app.post('/post/new', authController.authenticateToken, postController.create)
app.post('/post/delete', authController.authenticateToken, postController.delete)
