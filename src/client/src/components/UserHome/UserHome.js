import React, { Component } from 'react';
import CreatePost from './CreatePost';
import { Link } from 'react-router-dom';
import { getLocalUser } from '../../services/user';
import FormAction from '../Buttons/FormAction';

class UserHome extends Component {
    constructor(props) {
        super(props)
        this.state = { user: [], response: ''}
    }

    /* On component inital render */
    componentDidMount() {
        /* Calling API to gather local user information */
        getLocalUser(localStorage.getItem("username"))
            .then(user => {
                this.setState({...this.state, user: {...user.data, posts: user.data.posts.reverse()}})
                /* Conditional check to see if user has made any posts */
                this.state.user.posts.length > 0 ? 
                /* Using spread operations to ensure that the rest of the state is unchanged */
                this.setState({...this.state, response: `or, make some changes to your posts?`}) :
                this.setState({...this.state, response: `you don't seem to have any posts, you should add some!`})
            })
            .catch(err => {
                window.location.href="/"
            })
    }

    render() {
        return (
            <div class="text-center">
                <h2>Hey, {localStorage.getItem("username")}!</h2>
                {/* <h2>Hello, friend</h2> */}
                {/* <h3>Create a post?</h3> */}
                <CreatePost />
                {/* Conditional render,
                    renders the user's posts, populated with the respective URL,
                    text, and delete button.
                    Also renders appropriate response dependant on whether user has posts or not
                */}
                { this.state.user.posts ?
                    <div>
                        <h3>{this.state.response}</h3>
                        <ul>
                        {this.state.user.posts.map(post => {
                            return (
                            <li className="flex flex-row flex-wrap lg:w-1/2 m-auto md:max-h-72 lg:max-h-48 min-h-0 bg-opacity-30 bg-white rounded-lg my-4 shadow-md p-6" key={post._id}>
                                    <Link to={{pathname: `https://youtube.com/watch?v=${post.video_url}`}} target="_blank"><img className="max-h-36" src={`https://img.youtube.com/vi/${post.video_url}/0.jpg`} /></Link>
                                    <div className="text-center flex-wrap flex-auto overflow-ellipsis md:w-1/3 overflow-x-auto p-6 overflow-y-hidden">
                                        <p>{post.text_body} </p>
                                        <FormAction type="accept" label="Edit"/><FormAction type="decline" label="Delete" post={post}/>
                                        {/* <button class="bg-red-200 mx-2 px-1 rounded-md" onClick={e => deletePost(e, post)}>Delete</button> */}
                                    </div>
                            </li>)
                        })}
                        </ul>
                    </div>
                :
                <h3>{this.state.response}</h3>
                }
            </div>
        )
    }
}


export default UserHome