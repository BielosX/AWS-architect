import re

pathParamPattern = re.compile('{(\w+)}')

class Node:
    def __init__(self):
        self.methods = {}
        self.pathParam = None
        self.pathParamNode = None
        self.subResources = {}

    def add_handler(self, segments, pathParamId, method, handler):
        self.pathParam = pathParamId
        if not segments:
            self.methods[method] = handler
        else:
            head, *tail = segments
            m = pathParamPattern.match(head)
            if m:
                if self.pathParamNode:
                    self.pathParamNode.add_handler(tail, m.group(1), method, handler)
                else:
                    newNode = Node()
                    newNode.add_handler(tail, m.group(1), method, handler)
                    self.pathParamNode = newNode
            else:
                subResource = self.subResources.get(head)
                if subResource:
                    subResource.add_handler(tail, None, method, handler)
                else:
                    newNode = Node()
                    newNode.add_handler(tail, None, method, handler)
                    self.subResources[head] = newNode

    def route(self, segments, pathParams, prev, method):
        if self.pathParam and prev:
            pathParams[self.pathParam] = prev
        if not segments:
            m = self.methods.get(method)
            if not m:
                return None
            else:
                return (pathParams, m)
        else:
            head, *tail = segments
            subResource = self.subResources.get(head)
            if subResource:
                return subResource.route(tail, pathParams, head, method)
            else:
                if self.pathParamNode:
                    return self.pathParamNode.route(tail, pathParams, head, method)
                else:
                    return None

class Router:
    def __init__(self):
        self.root = Node()

    def add_handler(self, path, method, handler):
        segments = filter(lambda x: x, path.split("/"))
        self.root.add_handler(segments, None, method, handler)

    def route(self, path, method):
        segments = filter(lambda x: x, path.split("/"))
        return self.root.route(segments, {}, None, method)

