[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/isabela42/CAMeLS">
    <!-- <img src="images/pipelineSimplels.png" alt="Logo" width=400>-->
  </a>

  <h3 align="center">CAMeLS pipeline</h3>

  <p align="center">
    CRISPR Analysis Method for Library Screens
  </p>
</p>

<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li>
      <a href="#overview">Overview</a>
    </li>
    <li>
      <a href="#pipeline-prerequisites">Pipeline prerequisites</a>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## Overview

This repository contains the scripts used in our in-house CRISPR screen analysis pipeline that runs on a PBS cluster.

Each script file foccus on one part of the analysis, from looking at guide representation, through quality checks and statistical tests.

* 010 Quality check sequencing (1FastQC, 2MultiQC)
* 020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
* 030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
* 040 Statistical test (1MAGeCK; 2Bash summary)
* 050 Plot results (1MAGeCK)

<!-- GETTING STARTED -->
## Pipeline Prerequisites

To get a local copy up and running, make sure you have each script file prerequisites instaled and up to date. To run CAMeLS, you should start by cloning the repo 

   ```sh
   git clone https://github.com/isabela42/CAMeLS.git
   ```

<!-- USAGE EXAMPLES -->
## Usage

Each script can be executed in a PBS cluster by using the following command line:
 
```sh
bash script-name.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"
```

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- ACKNOWLEDGEMENTS
## Acknowledgements

* []()
* []()
* []() -->


<!-- CONTACT -->
## Contact

Please contact [Isabela Almeida](mailto:mb.isabela42@gmail.com) if you have any enquires.

<!-- LICENSE -->
## License

Distributed under the MIT License. See [LICENSE][license-url] for more information.


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/isabela42/CAMeLS.svg?style=for-the-badge
[contributors-url]: https://github.com/isabela42/CAMeLS/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/isabela42/CAMeLS.svg?style=for-the-badge
[forks-url]: https://github.com/isabela42/CAMeLS/network/members
[stars-shield]: https://img.shields.io/github/stars/isabela42/CAMeLS.svg?style=for-the-badge
[stars-url]: https://github.com/isabela42/CAMeLS/stargazers
[issues-shield]: https://img.shields.io/github/issues/isabela42/CAMeLS.svg?style=for-the-badge
[issues-url]: https://github.com/isabela42/CAMeLS/issues
[license-shield]: https://img.shields.io/github/license/isabela42/CAMeLS.svg?style=for-the-badge
[license-url]: https://github.com/isabela42/CAMeLS/blob/main/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/isabela42/
