from bs4 import BeautifulSoup
from urllib.request import Request,urlopen
from urllib.parse import urljoin
import time

base_url = "http://www.clien.net/cs2/bbs/board.php?bo_table=sold"
#base_url = "http://www.clien.net/cs2/bbs/board.php?bo_table=park"

url_request = Request(base_url,headers={'User-Agent': 'Mozilla/5.0'})


clien_tip_board = urlopen(url_request).read()

bs4_clien = BeautifulSoup(clien_tip_board,"html.parser")
find_mytr = bs4_clien.find_all("tr",attrs={'class':"mytr"})

base_id = int(find_mytr[0].find('td').get_text(strip=True))


your_search = "신발장"

while True:
    print("Read Clien board %s" % base_id)
    clien_tip_board = urlopen(url_request).read()

    bs4_clien = BeautifulSoup(clien_tip_board,"html.parser")
    find_mytr = bs4_clien.find_all("tr",attrs={'class':"mytr"})

    #print(find_mytr[0].find('td').get_text(strip=True))

    for t in find_mytr:
        #print(t.find('wr_id').get_text(strip=True))
        current_id = int(t.find('td').get_text(strip=True))
        category = t.find('td',attrs={'class':'post_category'}).get_text(strip=True)
        item = t.find('td',attrs={'class':'post_subject'}).get_text(strip=True).encode('cp949','ignore').decode('cp949')

#        print(current_id, base_id, category, your_search, item)
        if current_id > base_id and category == "[판매]" and your_search in item:
            #print(t)
            #print(t.find('td',attrs={'class':'post_category'}).get_text(strip=True))
            print("제목 : "+t.find('td',attrs={'class':'post_subject'}).get_text(strip=True).encode('cp949','ignore').decode('cp949'))
            print("url : "+urljoin(base_url,t.find('td',attrs={'post_subject'}).a.get('href')))
    #        print("글쓴이 : "+t.find('td',attrs={'class' : 'post_name'}).get_text(strip=True))
        elif current_id == base_id:
            base_id = current_id

    time.sleep(60)
