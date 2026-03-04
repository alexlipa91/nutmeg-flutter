from src import _create_app


def create_app():
    from src.bootstrap import init
    init()

    return _create_app()


# variable used by Gunicorn
app = create_app()


if __name__ == "__main__":
    # Used when running locally only. When deploying to Google App
    # Engine, a webserver process such as Gunicorn will serve the app. This
    # can be configured by adding an `entrypoint` to app.yaml.
    app.run(host="localhost", port=8080, debug=True)
