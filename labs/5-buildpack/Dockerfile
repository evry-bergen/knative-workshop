FROM gcr.io/triggermesh/knative-lambda-node10
ENV _HANDLER "handler.sayHelloAsync"

COPY . .
RUN npm install
ENTRYPOINT ["/opt/aws-custom-runtime"]
