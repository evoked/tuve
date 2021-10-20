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

const JoinRoom = () => {
    const [content, setContent] = useState([])
    const set = (data) => {
        setContent(content => [...content, data])
    }

    const socket = io("http://localhost:3001/api/test", {
    withCredentials: true,
    //   extraHeaders: {
        // "my-custom-header": "abcd"
    //   }
});

    socket.on('connect', (socket) => {
        console.log(socket, 'JOINED')
        // return set('user joined')

    })

    socket.on('userjoin', (result) => {
        console.log('users:', result)
    })
    // const setHelper = () => {

    // }
    
    useEffect(() => {
        console.log(content)
        console.log('content change')
    }, [content])
    // useEffect(() => {
    //     joinRoom()
    //     .then(res => {
    //             console.log(res)   
    //             setContent(res.text)})
    //     .catch(e => console.log(e))
    // }, [])
    return (
    <div>
        {/* <div>{content.map(content => content[content]}</div> */}
    </div>
    )
    
    }
export default JoinRoom