import React, { useEffect, useState } from 'react'
import { joinRoom } from '../../services/rooms.js'
import * as io from "socket.io-client"
// import host from '../../services/host'

//   auth: {
    // token: "123"
//   },
//   query: {
    // "my-key": "my-value"
//   }


// socket.on('userjoin', () => {
//         console.log('AAAH')
//     })


const socket = io("http://localhost:3001", {
    withCredentials: true,
    //   extraHeaders: {
        // "my-custom-header": "abcd"
    //   }
});

socket.on('connect', (socket) => {
    console.log('JOINED')
    // return set('user joined')
})

socket.on('userConnectionEvent', (result) => {
    console.log('EVENT: ' + result)
})

// socket.on('userMessage', (socket, msg) => {
//     console.log(socket, msg)
// // })
// socket.on('userMessage', (socket, message) => {
//     // console.log(message)
//     // setContent(message)
//     console.log(socket, message)
// })
const JoinRoom = () => {
    const [content, setContent] = useState({})
    const [message, setMessage] = useState('')
    // const set = (data) => {
    //     setContent(content => [...content, data])
    // }

    // socket.on('userConnect', () => {
    //     console.log('user has connected')
    // })
    useEffect(() => {
        socket.on('userMessage', (socket, message) => {
            console.log(socket, message)
            addMessage(message)
        })

        return() => {
            socket.emit('disconnect')
        }
    }, [])
    
    const addMessage = (msg) => {
        setContent({message: msg})
        console.log(content)
    }
    // const addMessage = (msg) => {
    //     setContent({message: msg})
    //     console.log(content)
    // }

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

    // useEffect(() => {
        // console.log(content)
    // }, [content])
    // useEffect(() => {
    //     joinRoom()
    //     .then(res => {
    //             console.log(res)   
    //             setContent(res.text)})
    //     .catch(e => console.log(e))
    // }, [])
    
    return (
    <div>
        <form onSubmit={sendMessage}>
            <input className='text-black' type='text' value={message} onChange={handleChange} onSubmit={sendMessage} /><button>Send</button>
        </form>
        {/* <div>{content.map(content => content[content]}</div> */}
    </div>
    )
    
    }
export default JoinRoom