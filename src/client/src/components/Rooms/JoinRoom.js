import React, { memo, useEffect, useState } from 'react'
import { joinRoom } from '../../services/rooms.js'
import * as io from "socket.io-client"

const socket = io("http://localhost:3001", {
    withCredentials: true,
});

socket.on('connect', (socket) => {
    console.log('JOINED')
})

socket.on('userConnectionEvent', (result) => {
    console.log('EVENT: ' + result)
})


const JoinRoom = () => {
    const [content, setContent] = useState([])
    const [message, setMessage] = useState('')

    useEffect(() => {
        socket.on('userMessage', (socket, message) => {
            // addMessage(socket.id, message)
            // setSentMessage(socket.id, message)
            setContent(content => [...content, {user: socket.id, message: message}])
        })

        return() => {
            socket.emit('disconnect', socket)
        }
    }, [])


    const sendMessage = (e) => {
        e.preventDefault()
        if(message.length < 1) return
        socket.emit('userMessage', socket.id, message)
        setMessage('')
    }
    const handleChange = (e) => {
        e.preventDefault()
        setMessage(e.target.value)
    }

    return (
    <div className="m-3">
        <form onSubmit={sendMessage}>
            <input className='text-black' placeholder='send a message' type='text' value={message} onChange={handleChange} onSubmit={sendMessage} /><button>Send</button>
        </form>
        <div className="overflow-y-scroll overflow-x-hidden">
            <ul className="min-h-max max-h-96 flex flex-col my-2 max-w-screen-md">
                {content.map(message => {
                    return(
                        <li className="my-1 overflow-x-hidden ">
                            <p className="bg-gray-300 bg-opacity-25 max-w-min rounded-md">user</p>
                            <p>{message.message}</p>
                        </li>
                    )
                })}
            </ul>
        </div>
    </div>
    )
    
    }
export default JoinRoom