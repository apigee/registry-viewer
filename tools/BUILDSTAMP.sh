#!/bin/bash
#
# Copyright 2020 Google LLC. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BUILD="viewer/lib/build.dart"

echo "// Copyright 2020 Google LLC. All Rights Reserved." > $BUILD
echo "//" >> $BUILD
echo "// Licensed under the Apache License, Version 2.0 (the \"License\");" >> $BUILD
echo "// you may not use this file except in compliance with the License." >> $BUILD
echo "// You may obtain a copy of the License at" >> $BUILD
echo "//" >> $BUILD
echo "//    http://www.apache.org/licenses/LICENSE-2.0" >> $BUILD
echo "//" >> $BUILD
echo "// Unless required by applicable law or agreed to in writing, software" >> $BUILD
echo "// distributed under the License is distributed on an \"AS IS\" BASIS," >> $BUILD
echo "// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied." >> $BUILD
echo "// See the License for the specific language governing permissions and" >> $BUILD
echo "// limitations under the License." >> $BUILD
echo >> $BUILD
echo "// Time of most recent deployed build." >> $BUILD
echo "const buildTime = \"`date`\";" >> $BUILD
echo >> $BUILD
echo "// Commit of most recent deployed build." >> $BUILD
echo "const commitHash = \"`git rev-parse HEAD`\";"  >> $BUILD
