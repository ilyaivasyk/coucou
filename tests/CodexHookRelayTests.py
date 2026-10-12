import contextlib
import io
import json
import runpy
import sys
from unittest.mock import patch

for script in sys.argv[1:]:
    cases = [
        ('codex', 'PermissionRequest', False, False),
        ('codex', 'PreToolUse', True, False),
        ('codex', 'PostToolUse', True, False),
        ('', 'PermissionRequest', True, True),
    ]
    for agent, event, should_connect, should_allow in cases:
        payload = {'hook_event_name': event, 'session_id': 'test', 'tool_use_id': 'q1',
                   'tool_name': 'request_user_input_async',
                   'tool_input': {'questions': [{'title': 'Which option?', 'options': ['A', 'B']}]}}
        raw = io.TextIOWrapper(io.BytesIO(json.dumps(payload).encode()))
        output = io.StringIO()
        with patch('socket.socket') as socket, patch('sys.stdin', raw), \
             patch('sys.argv', [script, '--agent', agent] if agent else [script]), \
             contextlib.redirect_stdout(output):
            socket.return_value.recv.return_value = b'{"permissionDecision":"allow"}\n'
            try:
                runpy.run_path(script, run_name='__main__')
            except SystemExit as exit:
                assert exit.code in (None, 0)
            assert bool(socket.call_count) == should_connect, (script, agent, event)
            result = output.getvalue().strip()
            if should_allow:
                assert json.loads(result)['hookSpecificOutput']['decision']['behavior'] == 'allow'
            else:
                assert not result, (script, agent, event, result)
            if agent == 'codex' and should_connect:
                forwarded = json.loads(socket.return_value.sendall.call_args.args[0])
                assert forwarded['tool_input'] == payload['tool_input']
    print(script.rsplit('/', 1)[-1] + ': 4 Codex relay cases passed')
