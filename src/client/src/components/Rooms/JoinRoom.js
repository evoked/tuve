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


// const socketHelper = (c, sC) => {
    // return sC()
// }
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

    socket.on('event', (result) => {
        console.log(result)
    })


const JoinRoom = () => {
    const [content, setContent] = useState([])
    const [message, setMessage] = useState('')
    // const set = (data) => {
    //     setContent(content => [...content, data])
    // }
    socket.on('message', (message) => {
        // console.log(message)
        setContent([...content, message])
        console.log(content)
    })


    const sendMessage = (e) => {
        e.preventDefault()
        socket.emit('userMessage', message)
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
            <input type='text' value={message} onChange={handleChange} /><button>Send</button>
        </form>
        {/* <div>{content.map(content => content[content]}</div> */}
    </div>
    )
    
    }
export default JoinRoom