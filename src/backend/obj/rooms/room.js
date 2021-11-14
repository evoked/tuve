import {v4 as uuid4} from 'uuid'
// import queue from 'queue'

class Room {
    constructor(users, songQueue, owner, chat, _id) {
        this.users = users.length > 0 ? users : { users: []}
        this.songQueue = [{ post: [], username: [], _id: uuid4()}],
        this.currentSong = { isPaused: false}
        this.owner = owner,
        this.chat = [],
        this._id = uuid4()
        
        this.songQueue.autostart()
    }

    queueGet() {
        return this.songQueue
    }
    
    queueAdd(username, post, _id) {
        this.songQueue.push({})
    }

    pause() {
        this.song = { ...this.song, isPaused: !this.isPaused }
        this.songQueue.stop()
        return this.song.isPaused
    }

    pushCurrentSong(songName, username) {
        this.currentSong = { songName: songName, username: username, isPaused: false }
    }
    
    getCurrentSong() {
        return this.currentSong
    }
    


}