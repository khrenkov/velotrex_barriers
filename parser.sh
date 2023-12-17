#!/bin/bash

print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

print_header() {
    echo ""
    print_green "-----  $1  -----"
}

url="http://velotrex.ru/file_list.php"
barrier_url="http://velotrex.ru/trackview.php"
real="1"
country="Грузия"
country=$(printf "$country" | iconv -t CP1251)

barriers_dir="barriers"
mkdir -p $barriers_dir

out_file="out.html"
#echo $country
#kt="3"
#--data-urlencode "kt=$kt"
# curl -s --get --data-urlencode "country=$country" --data-urlencode "real=$real" $url | iconv -f CP1251 > $out_file
curl -s --get --data-urlencode "real=$real" $url | iconv -f CP1251 > $out_file


str_with_pages=$(grep $out_file -e "class='pagecounter'")
IFS='; ' read -r -a array <<< "$str_with_pages"
max_index=
for element in "${array[@]}"
do
    page=$(echo "$element" | grep '^[[:digit:]]' | cut -d '&' -f 1)
    if [[ ! -z $page ]]; then
        max_index=$page
    fi
done
rm $out_file

echo "Find $max_index pages with barriers"


# -------------------------------- Find indexes of barriers --------------------------------
print_header "Find indexes of barriers"
barrier_indexes=()

# for i in {1..${max_index}}
for (( i=1; i<=$max_index; i++ ))
do
    # curl $url/${i}.html | iconv -f windows-1251 >> out.$i
    echo "Download $i of $max_index page with list of barriers "
    # curl -s --get --data-urlencode "page=$i" --data-urlencode "order_field=o5" --data-urlencode "order_flag=ASC" --data-urlencode "country=$country" --data-urlencode "real=$real" $url | iconv -f CP1251 > $i
    curl -s --get --data-urlencode "page=$i" --data-urlencode "order_field=o5" --data-urlencode "order_flag=ASC" --data-urlencode "real=$real" $url | iconv -f CP1251 > $i
    
    

    sed -n /trackview.php/p $i > $i$i
    while IFS= read -r line; do
        IFS='= ' read -r -a array <<< "$line"
        barrier_index=
        for element in "${array[@]}"
        do
            barrier_index=$(echo "$element" | grep -P "^[[:digit:]]+'" | cut -d "'" -f 1)
            if [[ ! -z $barrier_index ]]; then 
                barrier_indexes+=($barrier_index)
            fi
        done
    done < $i$i
    rm $i$i
    rm $i    
done


# -------------------------------- Itarate over barrier indexes --------------------------------
print_header "Itarate over barrier indexes"
counter=1
for index in "${barrier_indexes[@]}"
do
    # echo $index
    curl -s --get --data-urlencode "file=$index" $barrier_url | iconv -f CP1251 > $index 

    barrier_name=
    barrier_difficult=
    barrier_file=
    barrier_region="noname"


    barrier_name_str=$(sed -n /Наименование/p $index)
    barrier_difficult_str=$(sed -n /Категория\ трудности/p $index)  
    barrier_file_str=$(sed -n /URL\:/p $index)
    # barrier_region_str=$(sed -n /Район\ \(подрайон\)/p $index)
    barrier_region_str=$(sed -n /id=\'td_region\'/p $index)

 
    

    # echo $barrier_name_str
    # echo $barrier_difficult_str
    # echo $barrier_file_str
    # echo $barrier_region_str
    
    if [[ ! -z $barrier_name_str ]]; then
        # barrier_name_str
        IFS='=' read -r -a array <<< "$barrier_name_str"            
        for element in "${array[@]}"
        do
            barrier_name_temp=$(echo "$element" | grep -P "'td_name'" | cut -d ">" -f 2 | cut -d "<" -f 1)
            if [[ ! -z $barrier_name_temp ]]; then                    
                barrier_name=$barrier_name_temp
                break
            fi
        done            
    fi

    # echo $barrier_name

    if [[ ! -z $barrier_difficult_str ]]; then
        # echo $barrier_difficult_str        
        IFS='=' read -r -a array <<< "$barrier_difficult_str"            
        for element in "${array[@]}"
        do
            barrier_difficult_temp=$(echo "$element" | grep -P "'par_value'" | cut -d ">" -f 2 | cut -d "<" -f 1)
            if [[ ! -z $barrier_difficult_temp ]]; then                    
                barrier_difficult=$barrier_difficult_temp
                break
            fi
        done                
    fi

    # echo $barrier_difficult

    if [[ ! -z $barrier_file_str ]]; then
        # echo $barrier_file_str 
        IFS='=' read -r -a array <<< "$barrier_file_str"            
        for element in "${array[@]}"
        do
            barrier_file_temp=$(echo "$element" | grep -P "'par_value'" | cut -d ">" -f 2 | cut -d "<" -f 1)
            if [[ ! -z $barrier_file_temp ]]; then                    
                barrier_file=$barrier_file_temp
                break
            fi
        done                       
    fi

    if [[ ! -z $barrier_region_str ]]; then
        # echo $barrier_region_str
        IFS='=' read -r -a array <<< "$barrier_region_str"            
        for element in "${array[@]}"
        do
            # echo $element
            # echo "$element" | grep -P "'td_region'" | cut -d ">" -f 2 | cut -d "<" -f 1
            barrier_region_temp=$(echo "$element" | grep -P "'td_region'" | cut -d ">" -f 2 | cut -d "<" -f 1)
            if [[ ! -z $barrier_region_temp ]]; then                    
                barrier_region=$barrier_region_temp
                break
            fi
        done            
    fi

    # echo $barrier_file

    rm $index

    mkdir -p "$barriers_dir/$barrier_region/"
    
    local_file_name="$barrier_difficult к.с. $barrier_name.gpx"

    # echo "${#barrier_indexes[@]}"

    print_yellow "$counter:${#barrier_indexes[@]} $local_file_name"

    curl -s --get  $barrier_file -o "$barriers_dir/$barrier_region/$local_file_name" 

    # barrier_name=
    # barrier_difficult=
    # barrier_file=
    counter=$((counter+1))

done

# Наименование
# Категория трудности
# URL:



# /file_list.php?page=1&order_field=o5&order_flag=ASC&country=Россия&real=1