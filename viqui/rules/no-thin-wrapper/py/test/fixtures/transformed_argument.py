def work():
    def activate(user):
        return set_state(user.upper(), "active")

    activate("user")
