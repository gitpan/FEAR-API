// Larbin
// Sebastien Ailleret
// 07-12-01 -> 07-12-01

#include <iostream.h>
#include <fstream>
#include <string.h>
#include <unistd.h>


#include "options.h"

#include "types.h"
#include "global.h"
#include "fetch/file.h"
#include "utils/text.h"
#include "utils/debug.h"
#include "interf/output.h"
#include "utils/MD5.h"


/** A page has been loaded successfully
 * @param page the page that has been fetched
 */

MD5 md5;

void loaded (html *page) {
  // Here should be the code for managing everything
  // page->getHeaders() gives a char* containing the http headers
  // page->getPage() gives a char* containing the page itself
  // those char* are statically allocated, so you should copy
  // them if you want to keep them
  // in order to accept \000 in the page, you can use page->getLength()
#ifdef BIGSTATS
  cout << "fetched : ";
  page->getUrl()->print();
  // cout << page->getHeaders() << "\n" << page->getPage() << "\n";
#endif // BIGSTATS


  char url[maxUrlSize];
  char digest[36] = {0};
  char output_filename[64];
  char headers[1024];
  unsigned int document_type;

  strcpy(headers, page->getHeaders());

  /* 
     Cache HTML and XML only
   */
  if( strstr(headers, "Content-Type: text/html")){
    document_type = 0;
  }
  else if( strstr(headers, "Content-Type: text/xml") ){
    document_type = 1;
  }
  else {
    return;
  }

  page->getUrl()->writeUrl(url);
  

  md5.reset();
  md5.append((const md5_byte_t *)url, strlen(url));
  md5.finish();

  for (int di = 0; di < 16; ++di){
    sprintf((digest+di*2), "%02x", (int)(md5.getDigest()[di]));
  }

  printf("%s\n%s\n\n", url, digest);

  std::ofstream output_file;
  sprintf(output_filename,
	  "/tmp/fear-api/pf/%c/%c/%s",
	  digest[0], digest[1], digest);
  output_file.open(output_filename, ios::binary | ios::out);
  if(output_file.is_open()){
    output_file << document_type << "\n";
    output_file << page->getPage();
    output_file.close();
  }
}

/** The fetch failed
 * @param u the URL of the doc
 * @param reason reason of the fail
 */
void failure (url *u, FetchError reason) {
  // Here should be the code for managing everything
#ifdef BIGSTATS
  cout << "fetched failed (" << (int) reason << ") : ";
  u->print();
#endif // BIGSTATS
}

/** initialisation function
 */
void initUserOutput () {

}

/** stats, called in particular by the webserver
 * the webserver is in another thread, so be careful
 * However, if it only reads things, it is probably not useful
 * to use mutex, because incoherence in the webserver is not as critical
 * as efficiency
 */
void outputStats(int fds) {
  ecrire(fds, "Nothing to declare");
}
