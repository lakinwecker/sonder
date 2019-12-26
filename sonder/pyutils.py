"""
Some helpers to work around bugs in python
"""
import collections

#-------------------------------------------------------------------------------
# We can't use defaultdicts with dataclasses.asdict because of:
# https://bugs.python.org/issue35540
# So we work around it by providing a class that can be default instantiated
# But is otherwise a defaultdict.
#-------------------------------------------------------------------------------

class DefaultDictInt(collections.defaultdict):
    def __init__(self, *args, **kwargs):
        super().__init__(int, *args, **kwargs)

