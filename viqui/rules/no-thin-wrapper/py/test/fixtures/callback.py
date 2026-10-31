def work():
    def submit():
        return request("send")

    register(submit)
