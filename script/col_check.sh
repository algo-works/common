#!/bin/bash

#################################################################################
#
#  Copyright (c) 2017 GO @algo.works
#
#  データの各列の値（データ型）確認 シェル
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy  
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights  
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     
# copies of the Software, and to permit persons to whom the Software is         
# furnished to do so, subject to the following conditions:                      
#                                                                               
# The above copyright notice and this permission notice shall be included in    
# all copies or substantial portions of the Software.                           
#                                                                               
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     
# THE SOFTWARE.                                                                 
#
#################################################################################

#################################################################################
#
# 引数の解説
# 1 : 対象ファイル名
# 2 : 対象ファイルの形式 c = CSV, t = TSV, 省略 = CSV
#
# 実行例 : sh ***.sh sample.txt t
#
#################################################################################

# sort高速化のためのおまじない
export LC_ALL=C

# 引数を受け取る
TARGET_FILE=$1

case $2 in
        c) DELIMITER_INPUT=',';;
        t) DELIMITER_INPUT='\t';;
        *) DELIMITER_INPUT='\t';;
esac

# IFSを変更して区切り文字を改行だけに設定
IFS_BACKUP=$IFS
IFS=$'\n'

# 対象ファイルの列数をカウント
NUM_COL=$(head -1 ${TARGET_FILE} | sed -e "s/$DELIMITER_INPUT/\n/g" | wc -l)
#NUM_COL=8

# 各列のユニーク数を算出して最大値を求める
############## 繰り返し処理開始 ##############
for i in `seq $NUM_COL`; do
#for i in `seq 1 8`; do
  cat ${TARGET_FILE} | awk -v "COL=$i" -v DELIMITER_INPUT=${DELIMITER_INPUT} 'BEGIN { FS = DELIMITER_INPUT; OFS = DELIMITER_INPUT } ; {print $COL}' | sed 1d | sort | uniq | grep -v '^\s*$' | wc -l >> _uniq_max.txt
done
############## 繰り返し処理終了 ##############

# 各列の値の種類数をファイル出力
TARGET_FILENAME=$(echo ${TARGET_FILE} | sed -e 's/^.*\///g')
head -1 ${TARGET_FILE} | sed -e "s/$DELIMITER_INPUT/\n/g" > _header.txt
paste _header.txt _uniq_max.txt > var_num_${TARGET_FILENAME}

# ユニーク数の最大値を求める
UNIQ_MAX=$(cat _uniq_max.txt | awk '{if(m<$1) m=$1} END{print m}')

# 結合キー用の新規ファイルを作成
file=col_check.txt
file2=_key.txt

if [ -e $file ]; then
  rm -f $file

  # 0から最大値までの連番ファイルを作成
  for i in $(seq 0 ${UNIQ_MAX})
  do
    echo $i >> $file
  done

else

  # 0から最大値までの連番ファイルを作成
  for i in $(seq 0 ${UNIQ_MAX})
  do
    echo $i >> $file
  done
fi

sed 1d $file > $file2


# 各列読み込み読み込み
############## 繰り返し処理開始 ##############
for i in `seq $NUM_COL`; do
#for i in `seq 1 8`; do

# 列の切り出し：ヘッダの抽出
cat ${TARGET_FILE} | awk -v "COL=$i" -v DELIMITER_INPUT=${DELIMITER_INPUT} 'BEGIN { FS = DELIMITER_INPUT; OFS = DELIMITER_INPUT } ; {print $COL}' | sed -n 1p | sed -e 's/^/0\t/g' > _header.txt

# 列の切り出し：値の抽出
#cat ${TARGET_FILE} | awk -v "COL=$i" -v DELIMITER_INPUT=${DELIMITER_INPUT} 'BEGIN { FS = DELIMITER_INPUT; OFS = DELIMITER_INPUT } ; {print $COL}' | sed 1d | sort | uniq | cat -n | sed -e 's/^ *//g' > _var.txt
cat ${TARGET_FILE} | awk -v "COL=$i" -v DELIMITER_INPUT=${DELIMITER_INPUT} 'BEGIN { FS = DELIMITER_INPUT; OFS = DELIMITER_INPUT } ; {print $COL}' | sed 1d | sort | uniq > _tmp.txt
paste $file2 _tmp.txt > _var.txt

# ヘッダと値を結合
cat _header.txt _var.txt > ${i}.txt

#sed -i -e 's/\t/,/g' ${i}.txt

# 前の列までの結合データと結合
join -t'	' -a 1 -1 1 -2 1  $file ${i}.txt > tmp.txt
#join -t, -a 1 -1 1 -2 1 -e NULL $file ${i}.txt > tmp.txt

# 結合元データのファイル名を変更
mv tmp.txt $file

# 列抽出ファイルの削除
rm -f ${i}.txt

done
############## 繰り返し処理終了 ##############

# 最終アウトプットの作成
mv $file col_check_${TARGET_FILENAME}

# 一時ファイルの削除
rm -f _*.txt

# IFSの変更を元に戻す
IFS=$IFS_BACKUP

exit 0;

