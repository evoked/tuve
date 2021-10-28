import React from 'react'
import {
  Switch,
  Route,
} from "react-router-dom"
import UsersList from './components/Users.js'
import Settings from './components/Settings.js'
import UserLogin from './components/UserLogin.js'
import NavUser from './components/Nav/NavUser.js'
import UserRegister from './components/UserRegister.js'
import CreatePost from './components/UserHome/CreatePost.js'
import RenderUser from './components/User/RenderUser.js'
import UserHome from './components/UserHome/UserHome.js'
import JoinRoom from './components/Rooms/JoinRoom.js'

class App extends React.Component {
  render() {
    return (
      <div class="min-h-screen min-w-screen">
      <div class="bg-white min-h-full max-h-full h-screen">
          <NavUser class="sticky top-5" />
          <Switch>
            <Route exact path="/" component={UserLogin}/>
            <Route path="/home" component={UserHome}/>
            <Route path="/settings" component={Settings} />
            <Route path="/room/join" component={JoinRoom}/>
            <Route path="/user" component={UsersList} />
            <Route path="/users" component={UsersList} />
            <Route path="/register" component={UserRegister} />
            <Route path="/post/new" component={CreatePost} />
            <Route path="/:username/:pageId" component={RenderUser}/>
            <Route path="*" ><p className="pageNotFound">404: not found</p></Route>
        </Switch>
      </div>
      </div>
    )
  }
}

export default App;
