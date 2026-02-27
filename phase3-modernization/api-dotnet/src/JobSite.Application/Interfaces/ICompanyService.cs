using JobSite.Core.DTOs;
using JobSite.Core.Models;

namespace JobSite.Application.Interfaces;

/// <summary>
/// Service interface for company-related operations
/// </summary>
public interface ICompanyService
{
    Task<Company?> GetCompanyByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<Company?> GetCompanyByUserIdAsync(string userId, CancellationToken cancellationToken = default);

    Task<IEnumerable<Company>> GetAllCompaniesAsync(CancellationToken cancellationToken = default);

    Task<Company> CreateCompanyAsync(string userId, CreateCompanyDto dto, CancellationToken cancellationToken = default);

    Task<Company> UpdateCompanyAsync(int id, CreateCompanyDto dto, CancellationToken cancellationToken = default);

    Task DeleteCompanyAsync(int id, CancellationToken cancellationToken = default);
}
