import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(__file__))

import mock_api


class MockApiContractTest(unittest.TestCase):
    def test_get_returns_ok(self):
        handler = mock_api.Handler.__new__(mock_api.Handler)
        responses = []

        class Dummy:
            def send_response(self, code=None):
                self.code = code

            def send_header(self, key, value):
                pass

            def end_headers(self):
                pass

            def write(self, data):
                responses.append(data)

        dummy = Dummy()
        handler.wfile = dummy
        handler.send_response = dummy.send_response
        handler.send_header = dummy.send_header
        handler.end_headers = dummy.end_headers
        handler.do_GET()
        self.assertEqual(responses[0], b'{"service":"mock","status":"ok"}')

    def test_problem_structure(self):
        payload = mock_api._problem(400, "INVALID_REQUEST", "Solicitud inválida", "detalle")
        data = json.loads(payload.decode("utf-8"))
        self.assertEqual(data["status"], 400)
        self.assertEqual(data["code"], "INVALID_REQUEST")
        self.assertIn("type", data)
        self.assertIn("title", data)
        self.assertIn("detail", data)
        self.assertTrue(data["type"].startswith("urn:pdf-extractext:"))

    def test_pages_positive(self):
        for name, pages in mock_api.PAGES.items():
            self.assertIsInstance(pages, int)
            self.assertGreater(pages, 0)


if __name__ == "__main__":
    unittest.main()
