def work():
    def activate(user):
        return set_state(user, "active", enabled=True)

    activate("user")
