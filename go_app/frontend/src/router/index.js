import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import AppLayout from '../components/AppLayout.vue'
import Login from '../views/Login.vue'
import Dashboard from '../views/Dashboard.vue'
import ConversationsList from '../views/conversations/ConversationsList.vue'
import ConversationDetail from '../views/conversations/ConversationDetail.vue'
import ContactsList from '../views/contacts/ContactsList.vue'
import ContactDetail from '../views/contacts/ContactDetail.vue'
import InboxesList from '../views/inboxes/InboxesList.vue'

const routes = [
  {
    path: '/login',
    name: 'login',
    component: Login,
    meta: { public: true },
  },
  {
    path: '/',
    component: AppLayout,
    children: [
      {
        path: '',
        redirect: '/conversations',
      },
      {
        path: 'dashboard',
        name: 'dashboard',
        component: Dashboard,
      },
      {
        path: 'conversations',
        name: 'conversations',
        component: ConversationsList,
      },
      {
        path: 'conversations/:id',
        name: 'conversation-detail',
        component: ConversationDetail,
      },
      {
        path: 'contacts',
        name: 'contacts',
        component: ContactsList,
      },
      {
        path: 'contacts/:id',
        name: 'contact-detail',
        component: ContactDetail,
      },
      {
        path: 'inboxes',
        name: 'inboxes',
        component: InboxesList,
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()

  if (to.meta.public) {
    if (auth.isLoggedIn) {
      return next('/conversations')
    }
    return next()
  }

  if (!auth.isLoggedIn) {
    return next('/login')
  }

  next()
})

export default router
