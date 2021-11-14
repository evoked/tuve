import {v4 as uuid4} from 'uuid'
// import queue from 'queue'
import _ from 'lodash'

class Room {
    constructor(users, songQueue, owner, chat, _id) {
        this.users = users.length > 0 ? users : { users: []}
        this.songQueue = [{ post, username, _id: uuid4()}],
        this.currentSong = { isPaused: false}
        this.owner = owner,
        this.chat = [],
        this._id = uuid4()
        this.playedSongs = [{ post, username, id}]
        
    }

    queueGet() {
        return this.songQueue
    }
    
    queueAdd(username, post, _id) {
        this.songQueue.push({post, username, _id})
        console.log('queue add')
    }

    // todo
    queuePop(_id) {
        this.playedSongs.push(...this.songQueue[0])
        this.
        // this.songQueue = _.remove(this.songQueue)
        console.log('queue pop')
    }
    
    queueRemove(_id) {

    }

    addPlayedSong() {
        this.playedSongs = {...this.playedSongs, this.}
    }

    userAdd(user) {
        this.users.push(user)
    }

    pause() {
        this.song = { ...this.song, isPaused: !this.isPaused }
        this.songQueue.stop()
        console.log('queue pause')
        return this.song.isPaused
    }

    pushCurrentSong(songName, username) {
        this.currentSong = { songName: songName, username: username, isPaused: false }
        console.log('currentSong replaced')
    }

    getCurrentSong() {
        return this.currentSong
    }
    
}