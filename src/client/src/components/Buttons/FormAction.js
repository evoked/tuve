import { deletePost } from '../../services/post';
import { userDelete, userLogout } from '../../services/user';

const FormType = (props) => {
    switch(props.type) {
        case('create'):
            return <button className="bg-blue-300 rounded-md px-1 mx-2 py-1" onClick={e => console.log(e)}>{props.label}</button>
        case('accept'):
            return <button className="bg-blue-300 rounded-md px-1 mx-2 py-1" onClick={e => console.log(e)}>{props.label}</button>
        case('decline'):
            switch(props.label){ 
                case('Delete'):
                    return <button className="bg-red-300 rounded-md mx-2 px-1 py-1 " onClick={e => deletePost(e,props.post)}>{props.label}</button>
                case('Logout'): 
                    return <button className="bg-red-300 rounded-md mx-2 px-1 py-1 " onClick={userLogout}>{props.label}</button>

            }
        case('delete-account'):
            return <button className="bg-gray-400 rounded-md mx-2 px-1 py-1 " 
                onClick={() => {
                    userDelete()
                    userLogout()
                }}> Delete Account </button>
    }
}

const FormAction = (props) => {
    return (FormType(props));
}

export default FormAction;